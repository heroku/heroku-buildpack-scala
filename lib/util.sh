#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Exports configuration variables of a buildpacks ENV_DIR to environment variables.
#
# Only configuration variables which names pass the positive pattern and don't match the negative pattern
# will be exported.
#
# Usage:
# ```
# util::export_env_dir "./env" "." "JAVA_OPTS|JAVA_TOOL_OPTIONS"
# ```
function util::export_env_dir() {
	local env_directory="${1}"
	local positive_pattern="${2:-"."}"
	local negative_pattern="^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH${3:+"|"}${3})$"

	for env_file in "${env_directory}"/*; do
		if [[ -f "${env_file}" ]]; then
			local env_name
			env_name="$(basename "${env_file}")"

			if [[ "${env_name}" =~ ${positive_pattern} ]] && ! [[ "${env_name}" =~ ${negative_pattern} ]]; then
				export "${env_name}=$(cat "${env_file}")"
			fi
		fi
	done
}

# Copies a subdirectory from source to destination, replacing any existing content.
#
# Usage:
# ```
# util::cache_copy ".gradle/wrapper" "${CACHE_DIR}" "${BUILD_DIR}"
# ```
function util::cache_copy() {
	local subdirectory="${1}"
	local source_directory="${2}"
	local destination_directory="${3}"

	local destination_path="${destination_directory}/${subdirectory}"
	local source_path="${source_directory}/${subdirectory}"

	rm -rf "${destination_path:?}"

	if [[ -d "${source_path}" ]]; then
		mkdir -p "${destination_path}"
		cp -pr "${source_path}"/. "${destination_path}"
	fi
}

# Returns the current time in milliseconds since epoch.
#
# Usage:
# ```
# timestamp=$(util::nowms)
# ```
function util::nowms() {
	date +%s%3N
}
