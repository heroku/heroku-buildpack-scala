#!/usr/bin/env bash

set -euo pipefail

get_property() {
	local prop_file="${1}"
	local prop_name="${2}"
	local prop_default="${3:-}"

	if [[ -f "${prop_file}" ]]; then
		local prop_value
		prop_value="$(sed '/^\#/d' "${prop_file}" | grep "${prop_name}" | tail -n 1 | cut -d "=" -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
		echo "${prop_value:-${prop_default}}"
	else
		echo "${prop_default}"
	fi
}
