#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  mkdir -p "${BUILD_DIR}/.heroku"
  touch "${BUILD_DIR}/.heroku/sbt-dependency-classpath.log"

  expected_release_output=`cat <<EOF
---

EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}

testReleaseWithPostgres()
{
  mkdir -p "${BUILD_DIR}/.heroku"
  cat << EOF > "${BUILD_DIR}/.heroku/sbt-dependency-classpath.log"
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.13.9/scala-library-2.13.9.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/twirl-api_2.13/1.5.1/twirl-api_2.13-1.5.1.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play-server_2.13/2.8.16/play-server_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play-logback_2.13/2.8.16/play-logback_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play-akka-http-server_2.13/2.8.16/play-akka-http-server_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/filters-helpers_2.13/2.8.16/filters-helpers_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play-guice_2.13/2.8.16/play-guice_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play-jdbc_2.13/2.8.16/play-jdbc_2.13-2.8.16.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/org/postgresql/postgresql/9.4-1206-jdbc42/postgresql-9.4-1206-jdbc42.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/modules/scala-xml_2.13/1.2.0/scala-xml_2.13-1.2.0.jar)
Attributed(/tmp/scala_buildpack_build_dir/.sbt_home/.cache/coursier/v1/https/repo1.maven.org/maven2/com/typesafe/play/play_2.13/2.8.16/play_2.13-2.8.16.jar)
EOF

  expected_release_output=`cat <<EOF
---

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

default_process_types:
  web: target/start -Dhttp.port=\\$PORT \\$JAVA_OPTS
EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}
