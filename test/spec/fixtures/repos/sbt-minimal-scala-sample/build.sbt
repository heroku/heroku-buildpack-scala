import NativePackagerKeys._

packageArchetype.java_application

name := """scala-getting-started"""

version := "1.0"

scalaVersion := "2.10.4"

mainClass in Compile := Some("com.example.Server")

libraryDependencies ++= Seq(
  "com.twitter" % "finagle-http_2.10" % "6.18.0",
  "postgresql" % "postgresql" % "9.0-801.jdbc4"
)
