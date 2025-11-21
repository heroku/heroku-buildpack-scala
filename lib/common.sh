#!/usr/bin/env bash

set -euo pipefail

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
