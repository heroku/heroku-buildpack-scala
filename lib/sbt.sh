#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

function sbt::install_sbt_launcher() {
	local sbt_version="${1}"
	local sbt_launcher_dir="${2}"

	mkdir -p "${sbt_launcher_dir}"
	local launcher_jar_path="${sbt_launcher_dir}/sbt-launch-${sbt_version}.jar"

	if [[ ! -f "${launcher_jar_path}" ]]; then
		output::step "Downloading sbt launcher ${sbt_version}..."
		sbt::download_sbt_launcher_jar "${sbt_version}" "${launcher_jar_path}"
	fi

	output::step "Setting up sbt launcher..."
	mkdir -p "${sbt_launcher_dir}/bin"
	cat <<-EOF >"${sbt_launcher_dir}/bin/sbt"
		#!/usr/bin/env bash

		# We determine this at runtime since the whole directory might be relocated later to make sbt available
		# at runtime.
		script_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
		java \${SBT_OPTS:-} -jar "\${script_dir}/../sbt-launch-${sbt_version}.jar" "\$@"
	EOF

	chmod +x "${sbt_launcher_dir}/bin/sbt"
}

function sbt::download_sbt_launcher_jar() {
	local sbt_version="${1}"
	local destination_path="${2}"

	local sbt_launcher_jar_url
	if [[ "${sbt_version}" == 0.* ]]; then
		sbt_launcher_jar_url="https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/${sbt_version}/sbt-launch.jar"
	else
		sbt_launcher_jar_url="https://repo.maven.apache.org/maven2/org/scala-sbt/sbt-launch/${sbt_version}/sbt-launch-${sbt_version}.jar"
	fi

	local http_status_code
	http_status_code=$(curl \
		--retry 3 \
		--retry-connrefused \
		--connect-timeout 5 \
		--silent \
		--show-error \
		--max-time 60 \
		--location \
		--write-out "%{http_code}" \
		--output "${destination_path}" \
		"${sbt_launcher_jar_url}")

	local curl_exit_code=$?

	if [[ "${http_status_code}" == "404" ]]; then
		output::error <<-EOF
			Error: The requested sbt launcher version isn't available.

			We couldn't find sbt launcher version ${sbt_version} in the
			Maven repository.

			Check that this sbt version has been released upstream:
			https://github.com/sbt/sbt/releases

			If it has, make sure that you are using the latest version
			of this buildpack, and haven't pinned to an older release:
			https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
			https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
		EOF

		metrics::set_string "failure_reason" "install_sbt::version_unavailable"
		exit 1
	elif [[ "${curl_exit_code}" -ne 0 || "${http_status_code}" != "200" ]]; then
		output::error <<-EOF
			Error: Unable to download sbt launcher.

			An error occurred while downloading the sbt launcher from:
			${sbt_launcher_jar_url}

			In some cases, this happens due to a temporary issue with
			the network connection or server.

			First, make sure that you are using the latest version
			of this buildpack, and haven't pinned to an older release:
			https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
			https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

			Then try building again to see if the error resolves itself.

			HTTP status code: ${http_status_code}, curl exit code: ${curl_exit_code}
		EOF

		metrics::set_string "failure_reason" "install_sbt::download_error"
		exit 1
	fi

	local sha1_path
	sha1_path=$(mktemp)

	if ! curl --silent --show-error --location "${sbt_launcher_jar_url}.sha1" >"${sha1_path}" 2>/dev/null; then
		output::error <<-EOF
			Error: Unable to download SHA-1 checksum for sbt launcher.
		EOF

		metrics::set_string "failure_reason" "install_sbt::checksum_unavailable"
		exit 1
	fi

	local expected_sha1
	expected_sha1=$(cat "${sha1_path}")

	local actual_sha1
	actual_sha1=$(sha1sum "${destination_path}" | cut -d' ' -f1)

	if [[ "${actual_sha1}" != "${expected_sha1}" ]]; then
		output::error <<-EOF
			Error: Checksum verification failed for sbt launcher.

			Expected: ${expected_sha1}
			Actual:   ${actual_sha1}
		EOF

		metrics::set_string "failure_reason" "install_sbt::checksum_mismatch"
		exit 1
	fi
}

function sbt::output_build_error_message() {
	local sbt_build_log_file="${1}"

	if grep --quiet --ignore-case 'Not a valid key: stage' "${sbt_build_log_file}"; then
		output::error <<-EOF
			Error: sbt 'stage' task not found.

			Your build definition does not define a valid 'stage' task, which is required
			for deployment on Heroku. This task should create a deployment-ready
			version of your application.

			The recommended way to add the 'stage' task is to use the sbt-native-packager
			plugin, which provides it automatically. Alternatively, you can define a
			custom 'stage' task that prepares your application for deployment.

			For more information, see:
			- https://www.scala-sbt.org/sbt-native-packager/
			- https://devcenter.heroku.com/articles/scala-support#build-behavior
		EOF

		metrics::set_string "failure_reason" "sbt_build::stage_task_not_found"
		return
	fi

	if grep --quiet --ignore-case -E '(Compilation failed|javac returned non-zero exit code)' "${sbt_build_log_file}"; then
		output::error <<-EOF
			Error: sbt build failed.

			Your application failed to compile. Check the build output above
			for specific compilation errors from the compiler.

			Common causes include:
			- Syntax errors in your source code
			- Type mismatches or missing implicit conversions
			- Unresolved symbols or missing imports
			- Incompatible API changes in dependencies

			Fix the compilation errors in your code and try deploying again.
		EOF

		metrics::set_string "failure_reason" "sbt_build::compilation_failed"
		return
	fi

	if grep --quiet --ignore-case 'is already defined as object' "${sbt_build_log_file}"; then
		output::error <<-EOF
			Error: sbt build failed.

			An error occurred during the sbt build process. This error typically
			indicates stale compilation artifacts in the cache that are conflicting
			with your current code.

			To fix this issue, run a clean build by setting:

			    $ heroku config:set SBT_CLEAN=true

			Then deploy again with 'git push'. After a successful build, you can
			remove the variable:

			    $ heroku config:unset SBT_CLEAN
		EOF

		metrics::set_string "failure_reason" "sbt_build::stale_cache"
		return
	fi

	output::error <<-EOF
		Error: sbt build failed.

		An error occurred during the sbt build process. This usually
		indicates an issue with your application's dependencies, configuration,
		or source code.

		First, check the build output above for specific error messages
		from sbt that might indicate what went wrong. Common issues include:

		- Missing or incompatible dependencies in your build.sbt
		- Compilation errors in your Scala/Java source code
		- Configuration problems in your project settings
		- Plugin compatibility issues

		If the error message isn't clear, try building locally with the
		same sbt version specified in project/build.properties to reproduce
		the issue.
	EOF

	metrics::set_string "failure_reason" "sbt_build::unknown"
}
