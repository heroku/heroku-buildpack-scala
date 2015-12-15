#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

DEFAULT_SBT_VERSION="0.13.7"
DEFAULT_PLAY_VERSION="2.3.4"
DEFAULT_SCALA_VERSION="2.11.1"
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

_primeSbtTestCache()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  # exit code of app compile is cached so it is consistant between runn
  local compileStatusFile=${SBT_TEST_CACHE}/${sbtVersion}/app/compile_status

  if [ ! -f ${compileStatusFile} ]; then
    [ -d ${SBT_TEST_CACHE}/${sbtVersion} ] && rm -r ${SBT_TEST_CACHE}/${sbtVersion}

    ORIGINAL_BUILD_DIR=${BUILD_DIR}
    ORIGINAL_CACHE_DIR=${CACHE_DIR}

    BUILD_DIR=${SBT_TEST_CACHE}/${sbtVersion}/app/build
    CACHE_DIR=${SBT_TEST_CACHE}/${sbtVersion}/app/cache
    mkdir -p ${BUILD_DIR} ${CACHE_DIR}

    _createSbtProject ${sbtVersion} ${BUILD_DIR}
    ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR} >/dev/null 2>&1
    echo "$?" > ${compileStatusFile}

    BUILD_DIR=${ORIGINAL_BUILD_DIR}
    CACHE_DIR=${ORIGINAL_CACHE_DIR}
  fi

  return $(cat ${compileStatusFile})
}

_primeIvyCache()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  ivy2_path=.sbt_home/.ivy2
  mkdir -p ${CACHE_DIR}/${ivy2_path}
  _primeSbtTestCache ${sbtVersion} && cp -r ${SBT_TEST_CACHE}/${sbtVersion}/app/cache/${ivy2_path}/cache ${CACHE_DIR}/${ivy2_path}
}

createPlayProject()
{
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local sbtVersion=${2:-${DEFAULT_SBT_VERSION}}
  local scalaVersion=${3:-${DEFAULT_SCALA_VERSION}}

  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
resolvers += "Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/"

addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "${playVersion}")
EOF

  cat > ${BUILD_DIR}/build.sbt <<EOF
scalaVersion := "${scalaVersion}"

TaskKey[Unit]("stage") in Compile := { println("${SBT_STAGING_STRING}") }
EOF

  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=${sbtVersion}
EOF
}

createSbtProject()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  _primeIvyCache ${sbtVersion}
  _createSbtProject ${sbtVersion}
}

###

testCompile()
{
  createSbtProject

  # create `testfile`s in CACHE_DIR and later assert `compile` copied them to BUILD_DIR
  mkdir -p ${CACHE_DIR}/.sbt_home/.ivy2
  touch    ${CACHE_DIR}/.sbt_home/.ivy2/testfile
  mkdir -p ${CACHE_DIR}/.sbt_home/bin
  touch    ${CACHE_DIR}/.sbt_home/bin/testfile

  # create fake old versions of files that should be cleaned up
  touch    ${CACHE_DIR}/.sbt_home/bin/sbt
  touch    ${CACHE_DIR}/.sbt_home/bin/sbt-launch-OLD.jar

  compile

  assertEquals 0 "${RETURN}"

 # setup
  assertTrue "Ivy2 cache should have been repacked." "[ -d ${BUILD_DIR}/.sbt_home/.ivy2 ]"
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

  # clean up
  assertEquals "Ivy2 cache should have been repacked for a non-play project" "" "$(diff -r ${BUILD_DIR}/.sbt_home/.ivy2 ${CACHE_DIR}/.sbt_home/.ivy2)"
  assertEquals "SBT home should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/bin ${CACHE_DIR}/.sbt_home/bin)"

  # re-deploy
  compile

  assertEquals 0 "${RETURN}"
  assertNotCaptured "Ivy cache should not be primed on re-run" "Priming Ivy Cache"
  assertNotCaptured "SBT should not be re-installed on re-run" "Building app with sbt"
  assertNotCaptured "SBT should not compile any new classes" "[info] Compiling"
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

testRemovePlayForkRun()
{
  createPlayProject
  mkdir -p ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/play-fork-run.sbt

  compile

  assertEquals 0 "${RETURN}"
  #assertCaptured "Warns about play-fork-run removal" "Removing project/play-fork-run.sbt."
  assertFalse "Removes play-fork-run" "[ -f ${BUILD_DIR}/project/play-fork-run.sbt ]"
}

testCompile_PrimeIvyCacheForPlay() {
  createPlayProject "2.3.7" "0.13.5" "2.11.1"

  compile

  assertEquals 0 "${RETURN}"
  assertCaptured "Ivy cache should be primed" "Priming Ivy cache (Scala-2.11, Play-2.3)... done"

  compile

  assertEquals 0 "${RETURN}"
  assertNotCaptured "Ivy cache should not be primed on re-run" "Priming Ivy Cache"
}


testCompile_Play20Project() {
  createSbtProject
  mkdir -p ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf
  compile
  assertEquals 0 "${RETURN}"
  assertTrue  "Ivy2 cache should have been repacked for a play project." "[ -d ${CACHE_DIR}/.sbt_home/.ivy2 ]"
  assertFalse "Ivy2 cache should not have been included in slug for a play project." "[ -d ${BUILD_DIR}/.sbt_home/.ivy2 ]"
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
  assertCapturedError "You must use a release version of sbt, sbt.version=0.11.0 or greater"
}

testComplile_BuildPropertiesFileWithUnsupportedOldVersion()
{
  createSbtProject "0.10.0"

  compile

  assertCapturedError "You have defined an unsupported sbt.version in project/build.properties"
  assertCapturedError "You must use a release version of sbt, sbt.version=0.11.0 or greater"
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
