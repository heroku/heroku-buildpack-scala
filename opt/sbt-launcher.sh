#!/usr/bin/env bash

if [ "$@" == "console" ]; then
  scalaLibraryJar=$(ls /app/target/universal/stage/lib | grep "org.scala-lang.scala-library")
  scalaVersion=$(expr ${scalaLibraryJar} : ".*-\(2\.[0-9]\+\.[0-9]\+\(\-[a-zA-Z0-9]\+\)\?\)\.jar")

  if [ -n "$scalaVersion" ]; then
    scalaHome="/tmp/scala-complete"
    mkdir -p ${scalaHome}
    scalaUrl="http://www.scala-lang.org/files/archive/scala-${scalaVersion}.tgz"

    echo -n "Installing Scala ${scalaVersion} compiler..."
    curl --silent --max-time 60 $scalaUrl | tar zxm -C $scalaHome
    echo " done"

    java -cp /app/target/universal/stage/lib/*:${scalaHome}/scala-${scalaVersion}/lib/* scala.tools.nsc.MainGenericRunner -usejavacp
    exit 0
  fi
fi

java -Duser.home=/app/.sbt_home -Divy.default.ivy.user.dir=/app/.sbt_home/.ivy2 -jar /app/.sbt_home/bin/sbt-launch.jar "$@"
