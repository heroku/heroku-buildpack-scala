#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2034  # Used by sourced scripts
BUILDPACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

# Variables shared by this whole module
METRICS_DATA_FILE=""
PREVIOUS_METRICS_DATA_FILE=""

# Initializes the environment required for metrics collection.
# Must be called before you can use any other functions from this file!
#
# Usage:
# ```
# metrics::init "${CACHE_DIR}" "scala"
# ```
function metrics::init() {
	local cache_dir="${1}"
	local buildpack_name="${2}"

	METRICS_DATA_FILE="${cache_dir}/metrics-data/${buildpack_name}"
	PREVIOUS_METRICS_DATA_FILE="${cache_dir}/metrics-data/${buildpack_name}-prev"
}

# Initializes the metrics collection environment by setting up data files.
#
# WARNING: This function prunes existing metrics should there be any.
#
# Usage:
# ```
# metrics::init "${CACHE_DIR}" "scala"
# metrics::setup
# ```
function metrics::setup() {
	if [[ -f "${METRICS_DATA_FILE}" ]]; then
		cp "${METRICS_DATA_FILE}" "${PREVIOUS_METRICS_DATA_FILE}"
	fi

	mkdir -p "$(dirname "${METRICS_DATA_FILE}")"
	echo "{}" >"${METRICS_DATA_FILE}"
}

# Sets a metric value as raw JSON data.
# The value parameter must be valid JSON value (number, boolean, string, etc.).
#
# NOTE: Strings must be wrapped in double quotes (use `metrics::set_string` for convenience).
#
# Usage:
# ```
# metrics::set_raw "build_duration" "42.5"
# metrics::set_raw "success" "true"
# metrics::set_raw "message" '"Hello World"'
# ```
function metrics::set_raw() {
	local key="${1}"
	local value="${2}"

	local new_data_file_contents
	new_data_file_contents=$(jq <"${METRICS_DATA_FILE}" --arg key "${key}" --argjson value "${value}" '. + { ($key): ($value) }')

	echo "${new_data_file_contents}" >"${METRICS_DATA_FILE}"
}

# Sets a metric value as a string.
# The value will be automatically wrapped in double quotes and escaped for JSON.
#
# Usage:
# ```
# metrics::set_string "buildpack_version" "1.2.3"
# metrics::set_string "jvm_distribution" "Heroku"
# ```
function metrics::set_string() {
	local key="${1}"
	local value="${2}"

	# This works because jq's `--arg` always results in a string value
	metrics::set_raw "${key}" "$(jq -n --arg value "${value}" '$value')"
}

# Sets a metric for elapsed time between two timestamps.
# If end timestamp is not provided, current time is used.
# Time is calculated in seconds with millisecond precision.
#
# Usage:
# ```
# start_time=$(util::nowms)
# # ... some operation ...
# metrics::set_duration "compile_duration" "${start_time}"
# ```
function metrics::set_duration() {
	local key="${1}"
	local start="${2}"
	local end="${3:-$(util::nowms)}"
	local time
	time="$(echo "${start}" "${end}" | awk '{ printf "%.3f", ($2 - $1)/1000 }')"
	metrics::set_raw "${key}" "${time}"
}

# Prints all metrics data in YAML format suitable for `bin/report`.
# Each metric key-value pair is output as a separate YAML line.
#
# Usage:
# ```
# metrics::print_bin_report_yaml
# ```
function metrics::print_bin_report_yaml() {
	jq -r 'keys[] as $key | (.[$key] | tojson) as $value | "\($key): \($value)"' <"${METRICS_DATA_FILE}"
}
