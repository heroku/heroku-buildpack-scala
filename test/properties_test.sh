#!/usr/bin/env bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/lib/properties.sh

testFileNotExists() {
  rm -f test.properties
  capture get_property "test.properties" "sbt.version" "foobar"
  assertCaptured "foobar"
}

testHappyPath() {
  echo "sbt.version=0.13.5" > test.properties
  capture get_property "test.properties" "sbt.version" "foobar"
  assertCaptured "0.13.5"
  rm test.properties
}

testDefault() {
  echo "maven.version=3.1.1" > test.properties
  capture get_property "test.properties" "sbt.version" "0.13.9"
  assertCaptured "0.13.9"
  rm test.properties
}

testMultipleProperties() {
  cat <<EOF > test.properties
sbt.version=0.13.7
java.runtime.version=1.8
EOF
  capture get_property "test.properties" "sbt.version" "foobar"
  assertCaptured "0.13.7"
  rm test.properties
}

testDuplicateProperties() {
  cat <<EOF > test.properties
sbt.version=0.11.5
java.runtime.version=1.8
sbt.version=0.13.9
EOF
  capture get_property "test.properties" "sbt.version" "foobar"
  assertCaptured "0.13.9"
  rm test.properties
}

testCommentedVersion() {
  cat <<EOF > test.properties
sbt.version=0.11.5
java.runtime.version=1.8
#sbt.version=0.13.9
EOF
  capture get_property "test.properties" "sbt.version" "foobar"
  assertCaptured "0.11.5"
  rm test.properties
}

testEmptyFile() {
  echo "" > test.properties
  capture get_property "test.properties" "sbt.version" "0.13.11"
  assertCaptured "0.13.11"
  rm test.properties
}

testWhitespace() {
  cat <<EOF > test.properties
sbt.version=0.11.5

java.runtime.version=1.8
maven.version = 3.3.9

foo.bar=splat
EOF
  capture get_property "test.properties" "maven.version" "foobar"
  assertCaptured "3.3.9"
  rm test.properties
}

testNoValue() {
  cat <<EOF > test.properties
sbt.version=0.11.5
java.runtime.version=1.8
maven.version=
EOF
  capture get_property "test.properties" "maven.version" "foobar"
  assertCaptured ""
  rm test.properties
}
