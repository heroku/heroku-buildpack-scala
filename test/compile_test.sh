#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

DEFAULT_SBT_VERSION="0.11.0"
SBT_TEST_CACHE="/tmp/sbt-test-cache"
SBT_STAGING_STRING="THIS_STRING_WILL_BE_OUTPUT_DURING_STAGING"

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

  assertCapturedSuccess

  # setup
  assertTrue "Ivy2 cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/.ivy2/testfile ]"
  assertTrue "SBT bin cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/bin/testfile ]"
  assertTrue "Ivy2 cache should exist" "[ -d ${BUILD_DIR}/.ivy2/cache ]"
  assertFalse "Old SBT launch jar should have been deleted" "[ -f ${BUILD_DIR}/.sbt_home/bin/sbt-launch-OLD.jar ]"
  assertCaptured "SBT should have been installed" "Building app with sbt" 
  assertFileMD5 "fa57b75cbc45763b7188a71928f4cd9a" "${BUILD_DIR}/.sbt_home/bin/sbt-launch-${DEFAULT_SBT_VERSION}.jar"
  assertFileMD5 "13edddc0e7a326a8bce014363270b6cc" "${BUILD_DIR}/.sbt_home/bin/sbt.boot.properties"
  assertFileMD5 "7fef33ac6fc019bb361fa85c7dc07f7c" "${BUILD_DIR}/.sbt_home/.sbt/plugins/Heroku-${DEFAULT_SBT_VERSION}.scala"
  assertFileMD5 "13cf615379347d6f1ef10a4334f578f7" "${BUILD_DIR}/.sbt_home/.sbt/plugins/heroku-plugins-${DEFAULT_SBT_VERSION}.sbt"
  assertEquals "SBT script should have been copied from buildpack and replaced old version" "" "$(diff ${BUILDPACK_HOME}/opt/sbt-${DEFAULT_SBT_VERSION} ${BUILD_DIR}/.sbt_home/bin/sbt)"

  # run
  assertCaptured "SBT tasks to run should be output" "Running: sbt clean compile stage" 
  assertCaptured "SBT should run stage task" "${SBT_STAGING_STRING}" 
 
  # clean up
  assertEquals "Ivy2 cache should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/.ivy2 ${CACHE_DIR}/.sbt_home/.ivy2)"
  assertEquals "SBT home should have been repacked" "" "$(diff -r ${BUILD_DIR}/.sbt_home/bin ${CACHE_DIR}/.sbt_home/bin)"

  # re-deploy
  compile

  assertCapturedSuccess
  assertNotCaptured "SBT should not be re-installed on re-run" "Building app with sbt" 
  assertCaptured "SBT tasks to run should still be outputed" "Running: sbt clean compile stage" 
}

testCompile_WithNonDefaultVersion()
{
  local specifiedSbtVersion="0.11.1"
  assertNotEquals "Precondition" "${specifiedSbtVersion}" "${DEFAULT_SBT_VERSION}"

  createSbtProject ${specifiedSbtVersion}

  compile

  assertCapturedSuccess
  assertCaptured "Default version of SBT should always be installed" "Building app with sbt v${DEFAULT_SBT_VERSION}" 
  assertCaptured "Specified SBT version should actually be used" "Getting org.scala-tools.sbt sbt_2.9.1 ${specifiedSbtVersion}" 
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
  
  assertCapturedError "Failed to build app with SBT"  
}

testCompile_NoStageTask()
{
  createSbtProject
  rm ${BUILD_DIR}/build.sbt

  compile

  assertCapturedError "Not a valid key: stage"
  assertCapturedError "Failed to build app with SBT"
}

testComplile_NoBuildPropertiesFile()
{
  createSbtProject
  rm ${BUILD_DIR}/project/build.properties

  compile
  
  assertCapturedError "Error, your scala project must include project/build.properties and define sbt.version" 
  assertCapturedError "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  createSbtProject "0.10.0"

  compile
  
  assertCapturedError "Error, you have defined an unsupported sbt.version in project/build.properties" 
  assertCapturedError "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater"
}

testComplile_BuildPropertiesFileWithUnsupportedVersion()
{
  createSbtProject "0.11.0-RC"

  compile
  
  assertCapturedError "Error, you have defined an unsupported sbt.version in project/build.properties"
  assertCapturedError "You must use a release verison of sbt, sbt.version=${DEFAULT_SBT_VERSION} or greater"
}
