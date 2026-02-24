#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

function openjdk::install_openjdk_via_jvm_common_buildpack() {
	local build_dir="${1}"
	# The install_openjdk function from the JVM common buildpack requires the path to the host buildpack to write to the
	# export script so that OpenJDK can be found by subsequent buildpacks.
	local host_buildpack_dir="${2}"

	# Legacy behaviour for customers and testing code can override the download location of the heroku/jvm buildpack
	# with JVM_COMMON_BUILDPACK for testing and debugging purposes.
	local jvm_common_buildpack_tarball_url="${JVM_COMMON_BUILDPACK:-https://buildpack-registry.s3.dualstack.us-east-1.amazonaws.com/buildpacks/heroku/jvm.tgz}"

	local jvm_common_buildpack_tarball_path
	jvm_common_buildpack_tarball_path=$(mktemp)

	local jvm_common_buildpack_dir
	jvm_common_buildpack_dir=$(mktemp -d)

	curl \
		--connect-timeout 3 \
		--max-time 60 \
		--retry 5 \
		--retry-connrefused \
		--no-progress-meter \
		--fail \
		--location \
		"${jvm_common_buildpack_tarball_url}" \
		-o "${jvm_common_buildpack_tarball_path}"

	tar -xzm --directory "${jvm_common_buildpack_dir}" --strip-components=1 -f "${jvm_common_buildpack_tarball_path}"

	# This script translates non-JDBC compliant DATABASE_URL (and similar) environment variables into their
	# JDBC compatible counterparts and writes them to "JDBC_" prefixed environment variables. We source this script
	# here to allow customers to connect to their databases via JDBC during the build. If no database environment
	# variables are present, this script does nothing.
	# shellcheck source=/dev/null
	source "${jvm_common_buildpack_dir}/opt/jdbc.sh"

	# Run the main installation in a sub-shell to avoid it overriding library functions and global
	# variables in the host buildpack.
	(
		# shellcheck source=/dev/null
		source "${jvm_common_buildpack_dir}/bin/java"

		# See: https://github.com/heroku/heroku-buildpack-jvm-common/blob/main/bin/java
		install_openjdk "${build_dir}" "${host_buildpack_dir}"
	)

	# Since we run install_openjdk in a sub-shell, any environment variables set by it will not be available in this
	# (parent) shell. As documented in the jvm buildpack, we can source the modified export script from this (host)
	# buildpack to get the necessary changes.
	# shellcheck source=/dev/null
	source "${host_buildpack_dir}/export"
}
