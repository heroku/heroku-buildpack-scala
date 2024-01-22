import com.typesafe.sbt.SbtStartScript

name := "sbt-start-script-sample"

organization := "com.example"

version := "0.1"

scalaVersion := "2.10.4"

seq(SbtStartScript.startScriptForClassesSettings: _*)

libraryDependencies ++= Seq(
  "com.twitter"          % "finagle-http_2.10" % "6.18.0",
  "org.slf4j"            %  "slf4j-api"        % "1.6.4",
  "com.typesafe.akka"    %% "akka-actor"       % "2.3.2" ,
  "org.specs2"           %% "specs2"           % "1.13" % "test",
  "com.github.tototoshi" %% "scala-csv"        % "1.0.0",
  "org.scalaj"           %% "scalaj-http"      % "0.3.16"
)


TaskKey[Unit]("stage") in Compile := { println("THIS_STRING_WILL_BE_OUTPUT_DURING_STAGING") }
