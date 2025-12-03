#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

function sbt::install_sbt_runner() {
	local sbt_runner_version="${1}"
	local sbt_dir="${2}"

	local sbt_bin_path="${sbt_dir}/bin/sbt"

	if [[ -f "${sbt_bin_path}" ]]; then
		# Using --script-version here to check for the runner version, not the sbt version of the project which
		# might be completely different.
		local installed_version
		installed_version=$("${sbt_bin_path}" --script-version 2>/dev/null || echo "unknown")

		if [[ "${installed_version}" == "${sbt_runner_version}" ]]; then
			output::step "Using cached sbt runner ${sbt_runner_version}..."
			return
		fi
	fi

	output::step "Installing sbt runner ${sbt_runner_version}..."
	sbt::install_sbt_runner_distribution "${sbt_runner_version}" "${sbt_dir}"
}

function sbt::install_sbt_runner_distribution() {
	local sbt_runner_version="${1}"
	local destination_dir="${2}"

	local sbt_runner_url="https://github.com/sbt/sbt/releases/download/v${sbt_runner_version}/sbt-${sbt_runner_version}.tgz"
	local download_path
	download_path=$(mktemp)

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
		--output "${download_path}" \
		"${sbt_runner_url}")

	local curl_exit_code=$?

	if [[ "${http_status_code}" == "404" ]]; then
		output::error <<-EOF
			Error: The requested sbt runner version isn't available.

			We couldn't find sbt runner version ${sbt_runner_version} in the
			GitHub releases.

			Check that this sbt runner version has been released upstream:
			https://github.com/sbt/sbt/releases

			If it has, make sure that you are using the latest version
			of this buildpack, and haven't pinned to an older release:
			https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
			https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
		EOF

		metrics::set_string "failure_reason" "install_sbt_runner::version_unavailable"
		exit 1
	elif [[ "${curl_exit_code}" -ne 0 || "${http_status_code}" != "200" ]]; then
		output::error <<-EOF
			Error: Unable to download sbt runner.

			An error occurred while downloading sbt runner from:
			${sbt_runner_url}

			In some cases, this happens due to a temporary issue with
			the network connection or server.

			First, make sure that you are using the latest version
			of this buildpack, and haven't pinned to an older release:
			https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
			https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

			Then try building again to see if the error resolves itself.

			HTTP status code: ${http_status_code}, curl exit code: ${curl_exit_code}
		EOF

		metrics::set_string "failure_reason" "install_sbt_runner::download_error"
		exit 1
	fi

	local sha256_path
	sha256_path=$(mktemp)

	if ! curl --silent --show-error --location "${sbt_runner_url}.sha256" >"${sha256_path}" 2>/dev/null; then
		output::error <<-EOF
			Error: Unable to download SHA-256 checksum for sbt runner.
		EOF

		metrics::set_string "failure_reason" "install_sbt_runner::checksum_unavailable"
		exit 1
	fi

	local expected_sha256
	expected_sha256=$(cut -d' ' -f1 "${sha256_path}")

	local actual_sha256
	actual_sha256=$(sha256sum "${download_path}" | cut -d' ' -f1)

	if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
		output::error <<-EOF
			Error: Checksum verification failed for sbt runner.

			Expected: ${expected_sha256}
			Actual:   ${actual_sha256}
		EOF

		metrics::set_string "failure_reason" "install_sbt_runner::checksum_mismatch"
		exit 1
	fi

	rm -rf "${destination_dir}"
	mkdir -p "${destination_dir}"

	tar -xzf "${download_path}" -C "${destination_dir}" --strip-components=1

	# Remove large native sbt binaries that are not used by the buildpack. If a user requests to use sbtn at runtime,
	# the sbt runner will gracefully download them again.
	rm -f "${destination_dir}/bin/sbtn-"*
	# Remove Windows specific files
	rm -f "${destination_dir}/bin/sbt.bat"
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

	if grep --quiet --ignore-case 'Compilation failed' "${sbt_build_log_file}"; then
		output::error <<-EOF
			Error: sbt build failed.

			Your application failed to compile. Check the build output above
			for specific compilation errors from the Scala compiler.

			Common causes include:
			- Syntax errors in your Scala/Java source code
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
