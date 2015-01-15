#!/usr/bin/env bash

install_jvm_version() {
  local build_dir=$1

  # download the jvm-common package
  JVM_COMMON_BUILDPACK=${JVM_COMMON_BUILDPACK:-http://lang-jvm.s3.amazonaws.com/jvm-buildpack-common-v11.tar.gz}
  mkdir -p /tmp/jvm-common
  curl --silent --location $JVM_COMMON_BUILDPACK | tar xzm -C /tmp/jvm-common --strip-components=1
  . /tmp/jvm-common/bin/util
  . /tmp/jvm-common/bin/java

  # install JDK
  javaVersion=$(detect_java_version ${build_dir})
  status_pending "Installing OpenJDK ${java_version}"
  install_java ${build_dir} ${java_version}
  jdk_overlay ${build_dir}
  status_done
}
