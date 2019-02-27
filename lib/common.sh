#!/usr/bin/env bash

export BUILDPACK_STDLIB_URL="https://lang-common.s3.amazonaws.com/buildpack-stdlib/v7/stdlib.sh"

SBT_0_VERSION_PATTERN='sbt\.version=\(0\.1[1-3]\.[0-9]*\(-[a-zA-Z0-9_]*\)*\)$'
SBT_1_VERSION_PATTERN='sbt\.version=\(1\.[0-9]*\.[0-9]*\(-[a-zA-Z0-9_]*\)*\)$'

## SBT 0.10 allows either *.sbt in the root dir, or project/*.scala or .sbt/*.scala
detect_sbt() {
  local ctxDir=$1
  if _has_sbtFile $ctxDir || \
     _has_projectScalaFile $ctxDir || \
     _has_hiddenSbtDir $ctxDir || \
     _has_buildPropertiesFile $ctxDir ; then
    return 0
  else
    return 1
  fi
}

is_play() {
  _has_playConfig $1
}

is_sbt_native_packager() {
  local ctxDir=$1
  if [ -e "${ctxDir}"/project/plugins.sbt ]; then
    pluginVersionLine="$(grep "addSbtPlugin(.\+sbt-native-packager" "${ctxDir}"/project/plugins.sbt)"
    test -n "$pluginVersionLine"
  else
    return 1
  fi
}

_has_sbtFile() {
  local ctxDir=$1
  test -n "$(find $ctxDir -maxdepth 1 -name '*.sbt' -print -quit)"
}

_has_projectScalaFile() {
  local ctxDir=$1
  test -d $ctxDir/project && test -n "$(find $ctxDir/project -maxdepth 1 -name '*.scala' -print -quit)"
}

_has_hiddenSbtDir() {
  local ctxDir=$1
  test -d $ctxDir/.sbt && test -n "$(find $ctxDir/.sbt -maxdepth 1 -name '*.scala' -print -quit)"
}

_has_buildPropertiesFile() {
  local ctxDir=$1
  test -e $ctxDir/project/build.properties
}

_has_playConfig() {
  local ctxDir=$1
  test -e $ctxDir/conf/application.conf ||
      test "$IS_PLAY_APP" = "true" ||
      (test -n "$PLAY_CONF_FILE" &&
          test -e "$PLAY_CONF_FILE" &&
          test "$IS_PLAY_APP" != "false") ||
      (# test for default Play 2.3 and 2.4 setup.
          test -d $ctxDir/project &&
          test -r $ctxDir/project/plugins.sbt &&
          test -n "$(grep "addSbtPlugin(\"com.typesafe.play\" % \"sbt-plugin\"" $ctxDir/project/plugins.sbt | grep -v ".*//.*addSbtPlugin")" &&
          test -r $ctxDir/build.sbt &&
          test -n "$(grep "enablePlugins(Play" $ctxDir/build.sbt | grep -v ".*//.*enablePlugins(Play")" &&
          test "$IS_PLAY_APP" != "false")
}

_has_playPluginsFile() {
  local ctxDir=$1
  test -e $ctxDir/project/plugins.sbt
}

get_scala_version() {
  local ctxDir=$1
  local sbtUserHome=$2
  local launcher=$3
  local playVersion=$4

  if [ -n "${playVersion}" ]; then
    if [ "${playVersion}" = "2.3" ] || [ "${playVersion}" = "2.4" ]; then
      # if we don't grep for the version, and instead use `sbt scala-version`,
      # then sbt will try to download the internet
      scalaVersionLine="$(grep "scalaVersion" "${ctxDir}"/build.sbt | sed -E -e 's/[ \t\r\n]//g')"
      scalaVersion=$(expr "$scalaVersionLine" : ".\+\(2\.1[0-1]\)\.[0-9]")

      if [ -n "${scalaVersion}" ]; then
        echo "$scalaVersion"
      else
        echo "2.10"
      fi
    elif [ "${playVersion}" = "2.2" ]; then
      echo '2.10'
    elif [ "${playVersion}" = "2.1" ]; then
      echo '2.10'
    elif [ "${playVersion}" = "2.0" ]; then
      echo '2.9'
    else
      echo ''
    fi
  else
    echo ''
  fi
}

get_supported_play_version() {
  local ctxDir=$1
  local sbtUserHome=$2
  local launcher=$3

  if _has_playPluginsFile $ctxDir; then
    pluginVersionLine="$(grep "addSbtPlugin(.\+play.\+sbt-plugin" "${ctxDir}"/project/plugins.sbt | sed -E -e 's/[ \t\r\n]//g')"
    pluginVersion=$(expr "$pluginVersionLine" : ".\+\(2\.[0-4]\)\.[0-9]")
    if [ "$pluginVersion" != 0 ]; then
      echo -n "$pluginVersion"
    fi
  fi
  echo ""
}

get_supported_sbt_version() {
  local ctxDir=$1
  local sbtVersionPattern=${2:-$SBT_0_VERSION_PATTERN}
  if _has_buildPropertiesFile $ctxDir; then
    sbtVersionLine="$(grep -P '[ \t]*sbt\.version[ \t]*=' "${ctxDir}"/project/build.properties | sed -E -e 's/[ \t\r\n]//g')"
    sbtVersion=$(expr "$sbtVersionLine" : "$sbtVersionPattern")
    if [ "$sbtVersion" != 0 ] ; then
      echo "$sbtVersion"
    else
      echo ""
    fi
  else
    echo ""
  fi
}

prime_ivy_cache() {
  local ctxDir=$1
  local sbtUserHome=$2
  local launcher=$3

  if is_play $ctxDir ; then
    playVersion=`get_supported_play_version ${BUILD_DIR} ${sbtUserHome} ${launcher}`
  fi
  scalaVersion=$(get_scala_version "$ctxDir" "$sbtUserHome" "$launcher" "$playVersion")

  if [ -n "$scalaVersion" ]; then
    cachePkg=" (Scala-${scalaVersion}"
    if [ -n "$playVersion" ]; then
      cachePkg="${cachePkg}, Play-${playVersion}"
    fi
    cachePkg="${cachePkg})"
  fi
  status_pending "Priming Ivy cache${cachePkg}"
  if _download_and_unpack_ivy_cache "$sbtUserHome" "$scalaVersion" "$playVersion"; then
    status_done
  else
    echo " no cache found"
  fi
}

_download_and_unpack_ivy_cache() {
  local sbtUserHome=$1
  local scalaVersion=$2
  local playVersion=$3

  baseUrl="https://lang-jvm.s3.amazonaws.com/sbt/v8/sbt-cache"
  if [ -n "$playVersion" ]; then
    ivyCacheUrl="$baseUrl-play-${playVersion}_${scalaVersion}.tar.gz"
  else
    ivyCacheUrl="$baseUrl-base.tar.gz"
  fi

  curl --retry 3 --silent --max-time 60 --location $ivyCacheUrl | tar xzm -C $sbtUserHome
  if [ $? -eq 0 ]; then
    mv $sbtUserHome/.sbt/* $sbtUserHome
    rm -rf $sbtUserHome/.sbt
    return 0
  else
    return 1
  fi
}

has_supported_sbt_version() {
  local ctxDir=$1
  local supportedVersion="$(get_supported_sbt_version ${ctxDir} ${SBT_0_VERSION_PATTERN})"
  if [ -n "$supportedVersion" ] ; then
    return 0
  else
    return 1
  fi
}

has_supported_sbt_1_version() {
  local ctxDir=$1
  local supportedVersion="$(get_supported_sbt_version ${ctxDir} ${SBT_1_VERSION_PATTERN})"
  if [ -n "$supportedVersion" ] ; then
    return 0
  else
    return 1
  fi
}

has_old_preset_sbt_opts() {
  if [ "$SBT_OPTS" = "-Xmx384m -Xss512k -XX:+UseCompressedOops" ]; then
    return 0
  else
    return 1
  fi
}

count_files() {
  local location=$1
  local pattern=$2

  if [ -d ${location} ]; then
    find ${location} -name ${pattern} | wc -l | sed 's/ //g'
  else
    echo "0"
  fi
}

detect_play_lang() {
  local appDir=$1/app

  local num_scala_files=$(count_files ${appDir} '*.scala')
  local num_java_files=$(count_files ${appDir} '*.java')

  if   [ ${num_scala_files} -gt ${num_java_files} ] ; then
    echo "Scala"
  elif [ ${num_scala_files} -lt ${num_java_files} ] ; then
    echo "Java"
  else
    echo ""
  fi
}

is_app_dir() {
  test "$1" != "/app"
}

uses_universal_packaging() {
  local ctxDir=$1
  test -d $ctxDir/target/universal/stage/bin
}

_universal_packaging_procs() {
  local ctxDir=$1
  (cd $ctxDir; find target/universal/stage/bin -type f -executable)
}

_universal_packaging_proc_count() {
  local ctxDir=$1
  _universal_packaging_procs $ctxDir | wc -l
}

universal_packaging_default_web_proc() {
  local ctxDir=$1
  if [ $(_universal_packaging_proc_count $ctxDir) -eq 1 ]; then
    echo "web: $(_universal_packaging_procs $ctxDir) -Dhttp.port=\$PORT"
  fi
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. sbt stage | indent
output() {
  local logfile="$1"
  local c='s/^/       /'

  case $(uname) in
      Darwin) tee -a "$logfile" | sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
      *)      tee -a "$logfile" | sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

install_sbt_extras() {
  local optDir=${1}
  local sbtBinDir=${2}

  rm -f ${sbtBinDir}/sbt-launch*.jar #legacy launcher
  mkdir -p ${sbtBinDir}
  cp -p ${optDir}/sbt-extras.sh ${sbtBinDir}/sbt-extras
  cp -p ${optDir}/sbt-wrapper.sh ${sbtBinDir}/sbt

  chmod 0755 ${sbtBinDir}/sbt-extras
  chmod 0755 ${sbtBinDir}/sbt

  export PATH="${sbtBinDir}:$PATH"
}

run_sbt() {
  local javaVersion=$1
  local home=$2
  local launcher=$3
  local tasks=$4
  local buildLogFile=".heroku/sbt-build.log"

  echo "" > $buildLogFile

  status "Running: sbt $tasks"
  SBT_HOME="$home" sbt ${tasks} | output $buildLogFile

  if [ "${PIPESTATUS[*]}" != "0 0" ]; then
    handle_sbt_errors $buildLogFile
  fi
}

cache_copy() {
  rel_dir=$1
  from_dir=$2
  to_dir=$3
  rm -rf $to_dir/$rel_dir
  if [ -d $from_dir/$rel_dir ]; then
    mkdir -p $to_dir/$rel_dir
    cp -pr $from_dir/$rel_dir/. $to_dir/$rel_dir
  fi
}

install_jdk() {
  local install_dir=${1:?}
  local cache_dir=${2:?}

  let start=$(nowms)
  JVM_COMMON_BUILDPACK=${JVM_COMMON_BUILDPACK:-https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku/jvm.tgz}
  mkdir -p /tmp/jvm-common
  curl --retry 3 --silent --location $JVM_COMMON_BUILDPACK | tar xzm -C /tmp/jvm-common --strip-components=1
  source /tmp/jvm-common/bin/util
  source /tmp/jvm-common/bin/java
  source /tmp/jvm-common/opt/jdbc.sh
  mtime "jvm-common.install.time" "${start}"

  let start=$(nowms)
  install_java_with_overlay "${install_dir}" "${cache_dir}"
  mtime "jvm.install.time" "${start}"
}
