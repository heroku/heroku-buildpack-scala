#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  PATH: .jdk/bin:.sbt_home/bin:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  SBT_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  REPO: /app/.sbt_home/.ivy2/cache
addons:
  heroku-postgresql:dev

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
  PATH: .jdk/bin:.sbt_home/bin:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  SBT_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  REPO: /app/.sbt_home/.ivy2/cache
addons:
  heroku-postgresql:dev

default_process_types:
  web: target/start -Dhttp.port=\\$PORT \\$JAVA_OPTS 
EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}
