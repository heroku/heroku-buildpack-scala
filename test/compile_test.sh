#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# .sbt_home
# cache unpacking
# making ivy2 cache
# only using one version of sbt even though build might specify others?
# installation of SBT if doesn't exist
# clean up of old SBT
# use version number from var??
# ---> extraneous? some of the downloads don't have the version in the name,
# sha1 test
# sbt script gets copied to $SBT_BINDIR/sbt
# sbt.boot.properties is downloaded
# download plugins
# download plugin config
# building app
# failed build
# cache repacking
# no stage target
# build.sbt??
# force with sbt.version??
# build.sbt: TaskKey[Unit]("stage") in Compile := { println("Hello Staging!") }

DEFAULT_SBT_VERSION="0.11.0"

setupSbt()
{
  sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  cat > ${BUILD_DIR}/blah.scala <<EOF
object Hi {
  def main(args: Array[String]) = println("Hi!")
}
EOF

  cat > ${BUILD_DIR}/build.sbt <<EOF
TaskKey[Unit]("stage") in Compile := { println("Hello Staging!") }
EOF

  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=${sbtVersion}
EOF
}

_testComplile()
{
  setupSbt

  compile

  assertCapturedSuccess
  assertFileContains "Hello Staging!" "${STD_OUT}"
}

testComplile_NoBuildPropertiesFile()
{
  setupSbt
  rm ${BUILD_DIR}/project/build.properties

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, your scala project must include project/build.properties and define sbt.version" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  setupSbt "0.10.0"

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, you have defined an unsupported sbt.version in project/build.properties" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  setupSbt "0.11.0-RC"

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, you have defined an unsupported sbt.version in project/build.properties" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}
