name := "sbt-0.13.18-minimal-with-native-packager"

scalaVersion := "2.13.17"

libraryDependencies ++= Seq(
	"dev.zio" %% "zio-http" % "3.5.1"
)

import NativePackagerKeys._

packageArchetype.java_application
