#!/usr/bin/env bash

set -euo pipefail

SBT_0_VERSION_PATTERN='sbt\.version=\(0\.1[1-3]\.[0-9]\+\(-[a-zA-Z0-9_]\+\)*\)$'
SBT_1_VERSION_PATTERN='sbt\.version=\(1\.[1-9][0-9]*\.[0-9]\+\(-[a-zA-Z0-9_]\+\)*\)$'

is_play() {
	local app_dir="${1}"

	case "${IS_PLAY_APP:-}" in
	"true")
		return 0
		;;
	"false")
		return 1
		;;
	*)
		[[ -f "${app_dir}/${PLAY_CONF_FILE:-conf/application.conf}" ]] ||
			grep -E --quiet --no-messages '^\s*addSbtPlugin\(\s*("org\.playframework"|"com\.typesafe\.play")\s*%\s*"sbt-plugin"' "${app_dir}/project/plugins.sbt"
		;;
	esac
}

is_sbt_native_packager() {
	local ctx_dir="${1}"
	if [[ -e "${ctx_dir}"/project/plugins.sbt ]]; then
		plugin_version_line="$(grep "addSbtPlugin(.\+sbt-native-packager" "${ctx_dir}"/project/plugins.sbt || true)"
		test -n "${plugin_version_line}"
	else
		return 1
	fi
}

get_supported_sbt_version() {
	local ctx_dir="${1}"
	local sbt_version_pattern="${2:-${SBT_0_VERSION_PATTERN}}"
	if test -e "${ctx_dir}/project/build.properties"; then
		sbt_version_line="$(grep -P '[ \t]*sbt\.version[ \t]*=' "${ctx_dir}"/project/build.properties | sed -E -e 's/[ \t\r\n]//g' || true)"
		sbt_version="$(expr "${sbt_version_line}" : "${sbt_version_pattern}")"
		if [[ "${sbt_version}" != 0 ]]; then
			echo "${sbt_version}"
		else
			echo ""
		fi
	else
		echo ""
	fi
}

has_supported_sbt_version() {
	local ctx_dir="${1}"
	local supported_version
	supported_version="$(get_supported_sbt_version "${ctx_dir}" "${SBT_0_VERSION_PATTERN}")"
	if [[ -n "${supported_version}" ]]; then
		return 0
	else
		return 1
	fi
}

has_supported_sbt_1_version() {
	local ctx_dir="${1}"
	local supported_version
	supported_version="$(get_supported_sbt_version "${ctx_dir}" "${SBT_1_VERSION_PATTERN}")"
	if [[ -n "${supported_version}" ]]; then
		return 0
	else
		return 1
	fi
}

has_old_preset_sbt_opts() {
	if [[ "${SBT_OPTS:-}" = "-Xmx384m -Xss512k -XX:+UseCompressedOops" ]]; then
		return 0
	else
		return 1
	fi
}

is_app_dir() {
	test "${1}" != "/app"
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. sbt stage | indent
output() {
	local log_file="${1}"
	local c='s/^/       /'

	case $(uname) in
	Darwin) tee -a "${log_file}" | sed -l "${c}" ;; # mac/bsd sed: -l buffers on line boundaries
	*) tee -a "${log_file}" | sed -u "${c}" ;;      # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
	esac
}

install_sbt_extras() {
	local opt_dir="${1}"
	local sbt_bin_dir="${2}"

	rm -f "${sbt_bin_dir}"/sbt-launch*.jar #legacy launcher
	mkdir -p "${sbt_bin_dir}"
	cp -p "${opt_dir}"/sbt-extras.sh "${sbt_bin_dir}"/sbt-extras
	cp -p "${opt_dir}"/sbt-wrapper.sh "${sbt_bin_dir}"/sbt

	chmod 0755 "${sbt_bin_dir}"/sbt-extras
	chmod 0755 "${sbt_bin_dir}"/sbt

	export PATH="${sbt_bin_dir}:${PATH}"
}

run_sbt() {
	local home="${1}"
	local tasks="${2}"
	local build_log_file=".heroku/sbt-build.log"

	echo "" >"${build_log_file}"

	export SBT_EXTRAS_OPTS="${SBT_EXTRAS_OPTS:-}"

	output::step "Running: sbt ${tasks}"
	# shellcheck disable=SC2086  # We want word splitting for tasks
	if ! SBT_HOME="${home}" sbt ${tasks} | output "${build_log_file}"; then
		handle_sbt_errors "${build_log_file}"
		exit 1
	fi
}

write_sbt_dependency_classpath_log() {
	local home="${1}"

	export SBT_EXTRAS_OPTS="${SBT_EXTRAS_OPTS:-}"

	output::step "Collecting dependency information"
	SBT_HOME="${home}" sbt "show dependencyClasspath" | grep -o "Attributed\(.*\)" >.heroku/sbt-dependency-classpath.log || true
}

cache_copy() {
	rel_dir="${1}"
	from_dir="${2}"
	to_dir="${3}"
	rm -rf "${to_dir:?}/${rel_dir}"
	if [[ -d "${from_dir}/${rel_dir}" ]]; then
		mkdir -p "${to_dir}/${rel_dir}"
		cp -pr "${from_dir}/${rel_dir}"/. "${to_dir}/${rel_dir}"
	fi
}

install_jdk() {
	local install_dir=${1:?}
	local cache_dir=${2:?}

	JVM_COMMON_BUILDPACK="${JVM_COMMON_BUILDPACK:-https://buildpack-registry.s3.us-east-1.amazonaws.com/buildpacks/heroku/jvm.tgz}"
	mkdir -p /tmp/jvm-common
	curl --fail --retry 3 --retry-connrefused --connect-timeout 5 --silent --location "${JVM_COMMON_BUILDPACK}" | tar xzm -C /tmp/jvm-common --strip-components=1
	# shellcheck disable=SC1091  # External files from jvm-common buildpack
	source /tmp/jvm-common/bin/util
	# shellcheck disable=SC1091  # External files from jvm-common buildpack
	source /tmp/jvm-common/bin/java
	# shellcheck disable=SC1091  # External files from jvm-common buildpack
	source /tmp/jvm-common/opt/jdbc.sh

	install_java_with_overlay "${install_dir}" "${cache_dir}"
}
