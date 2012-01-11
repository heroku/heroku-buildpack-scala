#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# .sbt_home
# cache unpacking
# no project/build.properties
# no version 0.11.0 or greater
# use of -RC version
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


testComplile()
{
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
sbt.version=0.11.0
EOF

  compile

  assertCapturedSuccess
  assertFileContains "Hello Staging!" "${STD_OUT}"
}
