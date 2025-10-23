#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Reads the value of a key from a Java properties file
#
# ```
# java_properties:get "system.properties" "java.runtime.version"
# ```
function java_properties::get() {
	local file=${1:?}
	local key=${2:?}

	local escaped_key
	escaped_key="${key//\./\\.}"

	# Allow grep to fail (via `true`) for handling the case where the file or key is not found.
	local grep_result
	grep_result=$(grep -E "^${escaped_key}[[:space:]=]+" "${file}" 2>/dev/null || true)

	echo "${grep_result}" | sed -E -e "s/${escaped_key}([\ \t]*=[\ \t]*|[\ \t]+)([_A-Za-z0-9\.-]*).*/\2/g"
}
