#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

DEFAULT_SBT_VERSION="1.10.0"
DEFAULT_SCALA_VERSION="2.13.14"
SBT_TEST_CACHE="/tmp/sbt-test-cache"
SBT_STAGING_STRING="THIS_STRING_WILL_BE_OUTPUT_DURING_STAGING"

afterSetUp() {
  # Remove scala-specific build dir in case it's already there
  rm -rf /tmp/scala_buildpack_build_dir
  # Clear clean compiles...most apps don't need to clean by default
  unset SBT_CLEAN
  unset SBT_OPTS
}

_createSbtProject()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}
  local projectRoot=${2:-${BUILD_DIR}}

  cat > ${projectRoot}/WorldlyGreeter.scala <<EOF
object WorldlyGreeter {
  def main(args: Array[String]) = println("Hello, World!")
}
EOF

  cat > ${projectRoot}/build.sbt <<EOF
TaskKey[Unit]("stage") in Compile := { println("${SBT_STAGING_STRING}") }
EOF

  mkdir -p ${projectRoot}/project
  cat > ${projectRoot}/project/build.properties <<EOF
sbt.version=${sbtVersion}
EOF
}

createSbtProject()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  _createSbtProject ${sbtVersion}
}

###

testCompile()
{
  createSbtProject

  # create `testfile`s in CACHE_DIR and later assert `compile` copied them to BUILD_DIR
  mkdir -p ${CACHE_DIR}/.sbt_home/bin
  touch    ${CACHE_DIR}/.sbt_home/bin/testfile

  # create fake old versions of files that should be cleaned up
  touch    ${CACHE_DIR}/.sbt_home/bin/sbt
  touch    ${CACHE_DIR}/.sbt_home/bin/sbt-launch-OLD.jar

  compile

  assertEquals 0 "${RETURN}"

 # setup
  assertTrue "SBT bin cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/bin/testfile ]"
  assertFalse "Old SBT launch jar should have been deleted" "[ -f ${BUILD_DIR}/.sbt_home/bin/sbt-launch-OLD.jar ]"
  assertTrue "sbt launch script should be created" "[ -f ${BUILD_DIR}/.sbt_home/bin/sbt ]"
  assertTrue "sbt plugins dir should exist" "[ -d ${BUILD_DIR}/.sbt_home/plugins ]"
  assertTrue "sbt plugins should be compiled" "[ -d ${BUILD_DIR}/.sbt_home/plugins/target ]"
  assertTrue "sbt launcher should be installed" "[ -f ${BUILD_DIR}/.sbt_home/launchers/${DEFAULT_SBT_VERSION}/sbt-launch.jar ]"
  assertContains "SBT should have been installed" "Downloading sbt launcher for $DEFAULT_SBT_VERSION" "$(cat ${STD_ERR})"

  # run
  assertCaptured "SBT tasks to run should be output" "Running: sbt compile stage"
  assertCaptured "SBT should run stage task" "${SBT_STAGING_STRING}"
  assertTrue "system.properties was not cached" "[ -f $CACHE_DIR/system.properties ]"

  # clean up
  assertEquals "SBT home should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/bin ${CACHE_DIR}/.sbt_home/bin)"

  # re-deploy
  compile

  assertEquals 0 "${RETURN}"
  assertNotCaptured "SBT should not be re-installed on re-run" "Building app with sbt"

  # Something is wrong with incremental compile
  # assertNotCaptured "SBT should not compile any new classes" "[info] Compiling"

  assertNotCaptured "SBT should not resolve any dependencies" "[info] Resolving"
  assertCaptured "SBT tasks to run should still be outputed" "Running: sbt compile stage"
}

testCleanCompile()
{
  createSbtProject

  # set appropriate env to clean
  echo 'true' > $ENV_DIR/SBT_CLEAN

  compile

  assertEquals 0 "${RETURN}"
  assertCaptured "SBT tasks to run should still be outputed" "Running: sbt clean compile stage"
}

testCompile_Play20Project() {
  createSbtProject
  mkdir -p ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf
  compile
  assertEquals 0 "${RETURN}"
  assertFalse "Streams should not have been included in slug for a play project." "[ -d ${BUILD_DIR}/target/streams ]"
  assertFalse "Scala cache should not have been included in slug for a play project." "[ -d ${BUILD_DIR}/target/scala-2.9.1 ]"
}

testCompile_WithMultilineBuildProperties() {
  createSbtProject
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
foo=bar

sbt.version   =  0.13.5

abc=xyz
EOF
  compile
  assertContains "Multiline properties file should detect sbt version" "Downloading sbt launcher for 0.13.5" "$(cat ${STD_ERR})"
}

testCompile_BuildFailure()
{
  createSbtProject
  cat > ${BUILD_DIR}/MissingBracket.scala <<EOF
object MissingBracket {
  def main(args: Array[String) = println("This should not compile")
}
EOF

  compile

  assertEquals 1 "${RETURN}"
  assertCaptured "Failed to run sbt!"
}

testCompile_NoStageTask()
{
  createSbtProject
  rm ${BUILD_DIR}/build.sbt

  compile

  assertEquals 1 "${RETURN}"
  assertCaptured "Not a valid key: stage"
  assertCaptured "Failed to run sbt!"
}

testComplile_NoBuildPropertiesFile()
{
  createSbtProject
  rm ${BUILD_DIR}/project/build.properties

  compile

  assertCapturedError "Your scala project must include project/build.properties and define sbt.version"
}

testComplile_BuildPropertiesFileWithUnsupportedOldVersion()
{
  createSbtProject "0.10.0"

  compile

  assertCapturedError "You have defined an unsupported sbt.version in project/build.properties"
  assertCapturedError "For sbt 0.x you must use a version >= 0.11, for sbt 1.x you must use a version >= 1.1"
}

testComplile_BuildPropertiesFileWithRCVersion()
{
  createSbtProject "0.13.5-RC1"

  compile

  assertContains "SBT should have been installed" "Downloading sbt launcher for" "$(cat ${STD_ERR})"
}

testComplile_BuildPropertiesFileWithMServerVersion()
{
  createSbtProject "0.13.6-MSERVER-1"

  compile

  assertContains "SBT should have been installed" "Downloading sbt launcher for" "$(cat ${STD_ERR})"
}

testComplile_CreatesExportScript()
{
  createSbtProject

  compile

  assertEquals 0 "${RETURN}"
  assertTrue "Export script should be created" "[ -f export ]"
}
