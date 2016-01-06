#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xss512k
addons:
  - heroku-postgresql

EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}

testPlay20Release()
{
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf

  expected_release_output=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xss512k
addons:
  - heroku-postgresql

default_process_types:
  web: target/start -Dhttp.port=\\$PORT \\$JAVA_OPTS
EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}
