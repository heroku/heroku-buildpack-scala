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
SBT_TEST_CACHE="/tmp/sbt-test-cache"

createSbtProject()
{
  sbtVersion=${1:-${DEFAULT_SBT_VERSION}}
  projectRoot=${2:-${BUILD_DIR}}

  cat > ${projectRoot}/blah.scala <<EOF
object Hi {
  def main(args: Array[String]) = println("Hi!")
}
EOF

  cat > ${projectRoot}/build.sbt <<EOF
TaskKey[Unit]("stage") in Compile := { println("Hello Staging!") }
EOF

  mkdir -p ${projectRoot}/project
  cat > ${projectRoot}/project/build.properties <<EOF
sbt.version=${sbtVersion}
EOF
}

primeIvyCache()
{
  sbtVersion=${1:-${DEFAULT_SBT_VERSION}}

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

  mkdir -p ${CACHE_DIR}/.sbt_home
  cp -r ${SBT_TEST_CACHE}/${sbtVersion}/app/cache/.sbt_home/.ivy2 ${CACHE_DIR}/.sbt_home
}

testComplile()
{
  createSbtProject
  primeIvyCache

  mkdir -p ${CACHE_DIR}/.sbt_home/.ivy2
  mkdir -p ${CACHE_DIR}/.sbt_home/bin
  touch ${CACHE_DIR}/.sbt_home/.ivy2/testfile
  touch ${CACHE_DIR}/.sbt_home/bin/testfile

  compile

  assertCapturedSuccess
  assertFileContains "Hello Staging!" "${STD_OUT}"
  assertTrue "Ivy2 cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/.ivy2/testfile ]"
  assertTrue "SBT bin cache should have been unpacked" "[ -f ${BUILD_DIR}/.sbt_home/bin/testfile ]"
  assertTrue "Ivy2 cache should exist" "[ -d ${BUILD_DIR}/.ivy2/cache ]"
  assertFileContains "Building app with sbt" "${STD_OUT}"
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
