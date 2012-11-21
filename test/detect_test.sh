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

testDetect_ApplicationConfFileDetectsAsPlay20None()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/Build.scala
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf

  detect

  assertAppDetected "Play 2.x"
}

testDetect_ApplicationConfFileDetectsAsPlay20Equals()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/Build.scala
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf
  mkdir ${BUILD_DIR}/app
  touch ${BUILD_DIR}/app/something.java
  touch ${BUILD_DIR}/app/something.scala

  detect

  assertAppDetected "Play 2.x"
}


testDetect_ApplicationConfFileDetectsAsPlay20Scala()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/Build.scala
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf
  mkdir ${BUILD_DIR}/app
  touch ${BUILD_DIR}/app/something.scala
  mkdir ${BUILD_DIR}/app/views
  touch ${BUILD_DIR}/app/something.scala.html
  
  detect

  assertAppDetected "Play 2.x - Scala"
}

testDetect_ApplicationConfFileDetectsAsPlay20Java()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/Build.scala
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf
  mkdir ${BUILD_DIR}/app
  touch ${BUILD_DIR}/app/something.java
  mkdir ${BUILD_DIR}/app/views
  touch ${BUILD_DIR}/app/something.scala.html
  
  detect

  assertAppDetected "Play 2.x - Java"
}


testDetect_NotFound()
{
  detect  
  
  assertNoAppDetected
}
