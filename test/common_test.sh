#!/usr/bin/env bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/lib/common.sh

EXPECTED_VERSION=0.11.3

FAKE_VERSION="2.1"
RUN_SBT_OUTPUT="[info] ${FAKE_VERSION}.1"

### Mocks!

status() {
  echo "$1..."
}

status_pending() {
  echo -n "$1..."
}

status_done() {
  echo " done"
}

error() {
  echo "ERROR: $1"
}

_download_and_unpack_ivy_cache() {
  # don't actually do it!
  return 0
}

run_sbt() {
  # don't actually do it!
  echo "${RUN_SBT_OUTPUT}"
}

_createPlay_23_Project()
{
  local playVersion=$1
  local scalaVersion=$2

  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
resolvers += "Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/"

addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "${playVersion}")
EOF

  cat > ${BUILD_DIR}/build.sbt <<EOF
scalaVersion := "${scalaVersion}"
EOF

  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=0.13.5
EOF
}

### Tests

testPrimeIvyCache_NoApp() {
  capture prime_ivy_cache "${BUILD_DIR}"
  assertCaptured "Should have detected correct version" "Priming Ivy cache... done"
}

testPrimeIvyCache_Scala_210_Play_23() {
  _createPlay_23_Project "2.3.2" "2.10.4"
  capture prime_ivy_cache "${BUILD_DIR}"
  assertCaptured "Should have detected correct versions" "Priming Ivy cache (Scala-2.10, Play-2.3)... done"
}

testPrimeIvyCache_Scala_211_Play_23() {
  _createPlay_23_Project "2.3.2" "2.11.1"
  capture prime_ivy_cache "${BUILD_DIR}"
  assertCaptured "Should have detected correct versions" "Priming Ivy cache (Scala-2.11, Play-2.3)... done"
}

testGetScalaVersion_Play_23()
{
  cat > ${BUILD_DIR}/build.sbt <<EOF
scalaVersion := "2.10.4"
EOF
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.3"
  assertCapturedSuccess
  assertCapturedEquals "2.10"

  cat > ${BUILD_DIR}/build.sbt <<EOF
scalaVersion := "2.11.1"
EOF
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.3"
  assertCapturedSuccess
  assertCapturedEquals "2.11"

  cat > ${BUILD_DIR}/build.sbt <<EOF

EOF
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.3"
  assertCapturedSuccess
  assertCapturedEquals "2.10"
}

testGetScalaVersion_Play_22()
{
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.2"
  assertCapturedSuccess
  assertCapturedEquals "2.10"
}

testGetScalaVersion_Play_21()
{
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.1"
  assertCapturedSuccess
  assertCapturedEquals "2.10"
}

testGetScalaVersion_Play_20()
{
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "2.0"
  assertCapturedSuccess
  assertCapturedEquals "2.9"
}

testGetScalaVersion_PlayUnsupported()
{
  capture get_scala_version "${BUILD_DIR}" ".sbt" "null" "1.2"
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetScalaVersion_Sbt()
{
  capture get_scala_version "${BUILD_DIR}"
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSbtVersionFileMissing()
{
  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSbtVersionMissing()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
some.prop=1.2.3
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSupportedSbtVersion()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=0.12.0
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "0.12.0"
}

testGetUnsupportedSbtVersion()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=0.10.0
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSbtVersionOnSingleLine_Unix()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${BUILD_DIR}/project/build.properties)"

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionOnMutipleLines_Unix()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
something.before= 0.0.0
sbt.version=${EXPECTED_VERSION}
something.after=1.2.3
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${BUILD_DIR}/project/build.properties)"

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}


testGetSbtVersionOnSingleLine_Windows()
{
  mkdir -p ${BUILD_DIR}/project
  sed -e 's/$/\r/' > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a Windows file" "ASCII text, with CRLF line terminators" "$(file -b ${BUILD_DIR}/project/build.properties)"

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionOnMutipleLines_Windows()
{
  mkdir -p ${BUILD_DIR}/project
  sed -e 's/$/\r/' > ${BUILD_DIR}/project/build.properties <<EOF
something.before=1.2.3
sbt.version=${EXPECTED_VERSION}
something.after=2.2.2
EOF
  assertEquals "Precondition: Should be a Windows file" "ASCII text, with CRLF line terminators" "$(file -b ${BUILD_DIR}/project/build.properties)"

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionWithSpaces()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionWithTabs()
{
  mkdir -p ${BUILD_DIR}/project
  sed -e 's/ /\t/g' > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionWithReleaseCandidate()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}-RC3
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-RC3"
}

testGetSbtVersionWithBeta()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}-Beta1
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-Beta1"
}

testGetSbtVersionWithMServer()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}-MSERVER-1
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-MSERVER-1"
}

testGetSbtVersionDateNumbers()
{
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version   =    ${EXPECTED_VERSION}-20140730-062239
EOF

  capture get_supported_sbt_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-20140730-062239"
}

testGetSbtVersionWithNoSpaces() {
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version${EXPECTED_VERSION}
EOF
  capture get_supported_sbt_version ${BUILD_DIR}
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSbtVersionWithNoValue() {
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=
EOF
  capture get_supported_sbt_version ${BUILD_DIR}
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSbtVersionWithSimilarNames() {
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbts.version=0.11.0
sbt.vversion=0.11.0
sbt.version=${EXPECTED_VERSION}
EOF
  capture get_supported_sbt_version ${BUILD_DIR}
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetSbtVersionWithSimilarNameReverseOrder() {
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/build.properties <<EOF
sbt.version=${EXPECTED_VERSION}
sbts.version=0.11.0
sbt.vversion=0.11.0
EOF
  capture get_supported_sbt_version ${BUILD_DIR}
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testCountFiles() {
   mkdir -p ${BUILD_DIR}/two/three

   touch ${BUILD_DIR}/1.a
   touch ${BUILD_DIR}/1.x
   touch ${BUILD_DIR}/two/2.a
   touch ${BUILD_DIR}/two/2.ax
   touch ${BUILD_DIR}/two/three/3.a
   touch ${BUILD_DIR}/two/three/3.xa

   capture count_files ${BUILD_DIR} '*.a'
   assertCapturedSuccess
   assertCapturedEquals "3"
}

testCountFiles_BadDir() {
   mkdir -p ${BUILD_DIR}/something

   capture count_files ${BUILD_DIR}/something_else '*.a'
   assertCapturedSuccess
   assertCapturedEquals "0"
}

testDetectPlayLang_BadDir() {
  capture detect_play_lang non_existant_dir
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetSupportedPlayVersion_24() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.4.2")
EOF

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "2.4"
}

testGetSupportedPlayVersion_23() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.3.0")
EOF

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "2.3"
}

testGetSupportedPlayVersion_22() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.2.0")
EOF

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "2.2"
}

testGetSupportedPlayVersion_21() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("play" % "sbt-plugin" % "2.1.1")
EOF

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "2.1"
}

testGetSupportedPlayVersion_20() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("play" % "sbt-plugin" % "2.0.8")
EOF

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals "2.0"
}

testGetSupportedPlayVersion_NoPlugin() {
  mkdir -p ${BUILD_DIR}/conf ${BUILD_DIR}/project
  touch ${BUILD_DIR}/conf/application.conf
  touch ${BUILD_DIR}/project/plugins.sbt

  capture get_supported_play_version ${BUILD_DIR}

  assertCapturedSuccess
  assertCapturedEquals ""
}

test_is_sbt_native_packager_success() {
  mkdir -p ${BUILD_DIR}/project
  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "0.7.4")
EOF

  capture is_sbt_native_packager ${BUILD_DIR}

  assertCapturedSuccess
}

test_is_sbt_native_packager_failure() {
  mkdir -p ${BUILD_DIR}/project

  cat > ${BUILD_DIR}/project/plugins.sbt <<EOF
addSbtPlugin("com.typesafe.sbt" % "sbt-start-script" % "0.10.0")
EOF

  capture is_sbt_native_packager ${BUILD_DIR}

  assertEquals 1 "${RETURN}"
}
