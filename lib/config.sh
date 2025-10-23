#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Gets a Scala buildpack configuration value from environment variable or Java properties file
#
# This function supports reading Scala buildpack configuration from system.properties
# for backwards compatibility only. This is a deprecated, legacy feature that will be
# removed in a future release. New configurations should only use environment variables.
#
# Priority order: Java properties file > environment variable > default value
#
# When a value is found in the Java properties file, a deprecation warning is displayed
# and a metric is recorded to track usage of this legacy feature.
#
# ```
# config::get "${BUILD_DIR}" "sbt.clean" "SBT_CLEAN" "false"
# ```
function config::get() {
	local build_dir="${1:?}"
	local java_property_key="${2:?}"
	local env_var_name="${3:?}"
	local default_value="${4:-}"

	local property_value
	property_value="$(java_properties::get "${build_dir}/system.properties" "${java_property_key}")"

	if [[ -n "${property_value}" ]]; then
		metrics::set_raw "uses_system_property_configuration" "true"

		output::warning <<-EOF
			Warning: Configuring the Scala buildpack via system.properties is deprecated.

			You are using the ${java_property_key} property in system.properties, which is
			deprecated and will be removed in a future buildpack release.

			Please migrate to using the ${env_var_name} environment variable instead.

			For more information on setting environment variables, see:
			https://devcenter.heroku.com/articles/config-vars
		EOF

		echo "${property_value}"
	else
		echo "${!env_var_name:-${default_value}}"
	fi
}
