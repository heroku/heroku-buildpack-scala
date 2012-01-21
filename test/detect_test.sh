#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetect_SbtFileFoundInRoot()
{
  touch ${BUILD_DIR}/something.sbt

  detect  

  assertAppDetected "Scala"
}

testDetect_ScalaFileFoundInProjectDir()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/something.scala

  detect

  assertAppDetected "Scala"
}

testDetect_ScalaFileFoundInScalaDir()
{
  mkdir ${BUILD_DIR}/.sbt
  touch ${BUILD_DIR}/.sbt/something.scala

  detect

  assertAppDetected "Scala"
}

testDetect_BuildPropertiesFileFoundInProjectDir()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/build.properties

  detect

  assertAppDetected "Scala"
}

testDetect_NotFound()
{
  detect  
  
  assertNoAppDetected
}
