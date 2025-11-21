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
