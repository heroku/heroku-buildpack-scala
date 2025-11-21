#!/usr/bin/env bash

set -euo pipefail

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

run_sbt() {
	local tasks="${1}"
	local build_log_file=".heroku/sbt-build.log"
	mkdir -p "$(dirname "${build_log_file}")"
	echo "" >"${build_log_file}"

	output::step "Running: sbt ${tasks}"
	# shellcheck disable=SC2086  # We want word splitting for tasks
	if ! sbt ${tasks} | output "${build_log_file}"; then
		handle_sbt_errors "${build_log_file}"
		exit 1
	fi
}

write_sbt_dependency_classpath_log() {
	export SBT_EXTRAS_OPTS="${SBT_EXTRAS_OPTS:-}"

	output::step "Collecting dependency information"
	sbt "show dependencyClasspath" | grep -o "Attributed\(.*\)" >.heroku/sbt-dependency-classpath.log || true
}
