#!/usr/bin/env bash

case $(ulimit -u) in
16384) # PM Dyno
  maxSbtHeap="2000"
  ;;
32768) # PL Dyno
  maxSbtHeap="5220"
  ;;
*)
  maxSbtHeap="768"
  ;;
esac

sbtHome="${SBT_HOME:-"$HOME"}"

sbt-extras ${SBT_EXTRAS_OPTS} \
  -J-Xmx${maxSbtHeap}M \
  -J-Xms${maxSbtHeap}M \
  -J-XX:+UseCompressedOops \
  -sbt-dir $sbtHome \
  -ivy $sbtHome/.ivy2 \
  -sbt-launch-dir $SBT_HOME/launchers \
  -Duser.home=$sbtHome \
  -Divy.default.ivy.user.dir=$sbtHome/.ivy2 \
  -Dfile.encoding=UTF8 \
  -Dsbt.global.base=$sbtHome \
  $(([ -n "$HEROKU_TEST_RUN_ID" ] || [[ "$DYNO" != *run.* ]]) && echo "-Dsbt.log.noformat=true -batch") -no-colors \
  "$@"
