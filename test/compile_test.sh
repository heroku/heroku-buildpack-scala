#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# .sbt_home
# only using one version of sbt even though build might specify others?
# installation of SBT if doesn't exist
# clean up of old SBT
# use version number from var??
# ---> extraneous? some of the downloads don't have the version in the name,
# sbt script gets copied to $SBT_BINDIR/sbt
# sbt.boot.properties is downloaded
# no stage target
# build.sbt??
# force with sbt.version??

DEFAULT_SBT_VERSION="0.11.0"
SBT_TEST_CACHE="/tmp/sbt-test-cache"
SBT_STAGING_STRING="THIS_STRING_WILL_BE_OUTPUT_DURING_STAGING"

createSbtProject()
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

  if [ ! -d ${SBT_TEST_CACHE}/${sbtVersion} ]; then
    ORIGINAL_BUILD_DIR=${BUILD_DIR}
    ORIGINAL_CACHE_DIR=${CACHE_DIR}

    BUILD_DIR=${SBT_TEST_CACHE}/${sbtVersion}/app/build
    CACHE_DIR=${SBT_TEST_CACHE}/${sbtVersion}/app/cache
    mkdir -p ${BUILD_DIR} ${CACHE_DIR}

    createSbtProject ${sbtVersion} ${BUILD_DIR}
    ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}

    BUILD_DIR=${ORIGINAL_BUILD_DIR}
    CACHE_DIR=${ORIGINAL_CACHE_DIR}
  fi
}

primeIvyCache()
{
  local sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

  _primeSbtTestCache ${sbtVersion}
  
  ivy2_path=.sbt_home/.ivy2
  mkdir -p ${CACHE_DIR}/${ivy2_path}
  cp -r ${SBT_TEST_CACHE}/${sbtVersion}/app/cache/${ivy2_path}/cache ${CACHE_DIR}/${ivy2_path}
}

###

testCompile()
{
  primeIvyCache
  createSbtProject
  
  # create `testfile`s in CACHE_DIR and later assert `compile` copied them to BUILD_DIR
  mkdir -p ${CACHE_DIR}/.sbt_home/.ivy2
  touch    ${CACHE_DIR}/.sbt_home/.ivy2/testfile
  mkdir -p ${CACHE_DIR}/.sbt_home/bin
  touch    ${CACHE_DIR}/.sbt_home/bin/testfile

  compile
  assertCapturedSuccess

  # setup
  assertTrue "Ivy2 cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/.ivy2/testfile ]"
  assertTrue "SBT bin cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/bin/testfile ]"
  assertTrue "Ivy2 cache should exist" "[ -d ${BUILD_DIR}/.ivy2/cache ]"
  assertFileContains "SBT should have been installed" "Building app with sbt" "${STD_OUT}"
  assertFileMD5 "fa57b75cbc45763b7188a71928f4cd9a" "${BUILD_DIR}/.sbt_home/bin/sbt-launch-${DEFAULT_SBT_VERSION}.jar"
  assertFileMD5 "7fef33ac6fc019bb361fa85c7dc07f7c" "${BUILD_DIR}/.sbt_home/.sbt/plugins/Heroku-${DEFAULT_SBT_VERSION}.scala"
  assertFileMD5 "13cf615379347d6f1ef10a4334f578f7" "${BUILD_DIR}/.sbt_home/.sbt/plugins/heroku-plugins-${DEFAULT_SBT_VERSION}.sbt"
  assertEquals "SBT script should have been copied from buildpack" "" "$(diff ${BUILDPACK_HOME}/opt/sbt-${DEFAULT_SBT_VERSION} ${BUILD_DIR}/.sbt_home/bin/sbt)"

  # run
  assertFileContains "SBT tasks to run should be output" "Running: sbt clean compile stage" "${STD_OUT}"
  assertFileContains "SBT should run stage task" "${SBT_STAGING_STRING}" "${STD_OUT}"
 
  # clean up
  assertEquals "Ivy2 cache should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/.ivy2 ${CACHE_DIR}/.sbt_home/.ivy2)"
  assertEquals "SBT home should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/bin ${CACHE_DIR}/.sbt_home/bin)"

  # re-deploy
  compile
  assertCapturedSuccess
  assertFileNotContains "SBT should not be re-installed on re-run" "Building app with sbt" "${STD_OUT}"
  assertFileContains "SBT tasks to run should still be outputed" "Running: sbt clean compile stage" "${STD_OUT}"
}

testCompile_BuildFailure()
{
  primeIvyCache
  createSbtProject
  cat > ${BUILD_DIR}/MissingBracket.scala <<EOF
object MissingBracket {
  def main(args: Array[String) = println("This should not compile")
}
EOF

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Failed to build app with SBT" "${STD_OUT}"
}

testComplile_NoBuildPropertiesFile()
{
  createSbtProject
  rm ${BUILD_DIR}/project/build.properties

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, your scala project must include project/build.properties and define sbt.version" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  createSbtProject "0.10.0"

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, you have defined an unsupported sbt.version in project/build.properties" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  createSbtProject "0.11.0-RC"

  compile
  
  assertEquals "1" "${RETURN}"
  assertFileContains "Error, you have defined an unsupported sbt.version in project/build.properties" "${STD_OUT}"
  assertFileContains "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater" "${STD_OUT}"
}
