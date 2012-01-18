#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  PATH: .sbt_home/bin:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  SBT_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  REPO: /app/.sbt_home/.ivy2/cache
addons:
  shared-database:5mb

EOF`

  release
  assertCapturedSuccess
  assertEquals "${expected_release_output}" "$(cat ${STD_OUT})"
}
