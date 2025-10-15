#!/usr/bin/env bash

set -euo pipefail

SBT_0_VERSION_PATTERN='sbt\.version=\(0\.1[1-3]\.[0-9]\+\(-[a-zA-Z0-9_]\+\)*\)$'
SBT_1_VERSION_PATTERN='sbt\.version=\(1\.[1-9][0-9]*\.[0-9]\+\(-[a-zA-Z0-9_]\+\)*\)$'

## SBT 0.10 allows either *.sbt in the root dir, or project/*.scala or .sbt/*.scala
detect_sbt() {
	local ctx_dir="${1}"
	if _has_sbt_file "${ctx_dir}" ||
		_has_project_scala_file "${ctx_dir}" ||
		_has_hidden_sbt_dir "${ctx_dir}" ||
		_has_build_properties_file "${ctx_dir}"; then
		return 0
	else
		return 1
	fi
}

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

_has_sbt_file() {
	local ctx_dir="${1}"
	test -n "$(find "${ctx_dir}" -maxdepth 1 -name '*.sbt' -print -quit)"
}

_has_project_scala_file() {
	local ctx_dir="${1}"
	test -d "${ctx_dir}/project" && test -n "$(find "${ctx_dir}/project" -maxdepth 1 -name '*.scala' -print -quit)"
}

_has_hidden_sbt_dir() {
	local ctx_dir="${1}"
	test -d "${ctx_dir}/.sbt" && test -n "$(find "${ctx_dir}/.sbt" -maxdepth 1 -name '*.scala' -print -quit)"
}

_has_build_properties_file() {
	local ctx_dir="${1}"
	test -e "${ctx_dir}/project/build.properties"
}

_has_play_plugins_file() {
	local ctx_dir="${1}"
	test -e "${ctx_dir}/project/plugins.sbt"
}

get_scala_version() {
	local ctx_dir="${1}"
	local sbt_user_home="${2}"
	local launcher="${3}"
	local play_version="${4}"

	if [[ -n "${play_version}" ]]; then
		if [[ "${play_version}" = "2.3" ]] || [[ "${play_version}" = "2.4" ]]; then
			# if we don't grep for the version, and instead use `sbt scala-version`,
			# then sbt will try to download the internet
			scala_version_line="$(grep "scalaVersion" "${ctx_dir}"/build.sbt | sed -E -e 's/[ \t\r\n]//g' || true)"
			scala_version="$(expr "${scala_version_line}" : ".\+\(2\.1[0-1]\)\.[0-9]")"

			if [[ -n "${scala_version}" ]]; then
				echo "${scala_version}"
			else
				echo "2.10"
			fi
		elif [[ "${play_version}" = "2.2" ]]; then
			echo '2.10'
		elif [[ "${play_version}" = "2.1" ]]; then
			echo '2.10'
		elif [[ "${play_version}" = "2.0" ]]; then
			echo '2.9'
		else
			echo ''
		fi
	else
		echo ''
	fi
}

get_supported_play_version() {
	local ctx_dir="${1}"
	local sbt_user_home="${2}"
	local launcher="${3}"

	if _has_play_plugins_file "${ctx_dir}"; then
		plugin_version_line="$(grep "addSbtPlugin(.\+play.\+sbt-plugin" "${ctx_dir}"/project/plugins.sbt | sed -E -e 's/[ \t\r\n]//g' || true)"
		plugin_version="$(expr "${plugin_version_line}" : ".\+\(2\.[0-4]\)\.[0-9]")"
		if [[ "${plugin_version}" != 0 ]]; then
			echo -n "${plugin_version}"
		fi
	fi
	echo ""
}

get_supported_sbt_version() {
	local ctx_dir="${1}"
	local sbt_version_pattern="${2:-${SBT_0_VERSION_PATTERN}}"
	if _has_build_properties_file "${ctx_dir}"; then
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

prime_ivy_cache() {
	local ctx_dir="${1}"
	local sbt_user_home="${2}"
	local launcher="${3}"
	local play_version=""

	if is_play "${ctx_dir}"; then
		play_version="$(get_supported_play_version "${BUILD_DIR}" "${sbt_user_home}" "${launcher}")"
	fi
	scala_version="$(get_scala_version "${ctx_dir}" "${sbt_user_home}" "${launcher}" "${play_version}")"

	if [[ -n "${scala_version}" ]]; then
		cache_pkg=" (Scala-${scala_version}"
		if [[ -n "${play_version}" ]]; then
			cache_pkg="${cache_pkg}, Play-${play_version}"
		fi
		cache_pkg="${cache_pkg})"
	fi
	output::step "Priming Ivy cache${cache_pkg}"
	if ! _download_and_unpack_ivy_cache "${sbt_user_home}" "${scala_version}" "${play_version}"; then
		output::step "No Ivy cache found, skipping priming"
	fi
}

_download_and_unpack_ivy_cache() {
	local sbt_user_home="${1}"
	local scala_version="${2}"
	local play_version="${3}"

	base_url="https://lang-jvm.s3.us-east-1.amazonaws.com/sbt/v8/sbt-cache"
	if [[ -n "${play_version}" ]]; then
		ivy_cache_url="${base_url}-play-${play_version}_${scala_version}.tar.gz"
	else
		ivy_cache_url="${base_url}-base.tar.gz"
	fi

	if curl --fail --retry 3 --retry-connrefused --connect-timeout 5 --silent --max-time 60 --location "${ivy_cache_url}" | tar xzm -C "${sbt_user_home}"; then
		shopt -s nullglob
		mv "${sbt_user_home}"/.sbt/* "${sbt_user_home}" 2>/dev/null || true
		shopt -u nullglob
		rm -rf "${sbt_user_home}"/.sbt
		return 0
	else
		return 1
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

count_files() {
	local location="${1}"
	local pattern="${2}"

	if [[ -d "${location}" ]]; then
		find "${location}" -name "${pattern}" | wc -l | sed 's/ //g'
	else
		echo "0"
	fi
}

detect_play_lang() {
	local app_dir="${1}/app"

	local num_scala_files
	local num_java_files
	num_scala_files="$(count_files "${app_dir}" '*.scala')"
	num_java_files="$(count_files "${app_dir}" '*.java')"

	if [[ "${num_scala_files}" -gt "${num_java_files}" ]]; then
		echo "Scala"
	elif [[ "${num_scala_files}" -lt "${num_java_files}" ]]; then
		echo "Java"
	else
		echo ""
	fi
}

is_app_dir() {
	test "${1}" != "/app"
}

uses_universal_packaging() {
	local ctx_dir="${1}"
	test -d "${ctx_dir}/target/universal/stage/bin"
}

_universal_packaging_procs() {
	local ctx_dir="${1}"
	(
		cd "${ctx_dir}" || exit
		find target/universal/stage/bin -type f -executable
	)
}

_universal_packaging_proc_count() {
	local ctx_dir="${1}"
	_universal_packaging_procs "${ctx_dir}" | wc -l
}

universal_packaging_default_web_proc() {
	local ctx_dir="${1}"
	if [[ "$(_universal_packaging_proc_count "${ctx_dir}")" -eq 1 ]]; then
		echo "web: $(_universal_packaging_procs "${ctx_dir}") -Dhttp.port=\$PORT"
	fi
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
	# shellcheck disable=SC2034  # Used in future versions
	local java_version="${1}"
	local home="${2}"
	local launcher="${3}"
	local tasks="${4}"
	local build_log_file=".heroku/sbt-build.log"

	echo "" >"${build_log_file}"

	output::step "Running: sbt ${tasks}"
	# shellcheck disable=SC2086  # We want word splitting for tasks
	if ! SBT_HOME="${home}" sbt ${tasks} | output "${build_log_file}"; then
		handle_sbt_errors "${build_log_file}"
		exit 1
	fi
}

write_sbt_dependency_classpath_log() {
	local home="${1}"
	local launcher="${2}"

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
