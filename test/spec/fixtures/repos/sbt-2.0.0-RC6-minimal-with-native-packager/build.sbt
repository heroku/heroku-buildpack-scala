name := "sbt-2.0.0-RC6-minimal-with-native-packager"

scalaVersion := "2.13.17"

libraryDependencies ++= Seq(
	"dev.zio" %% "zio-http" % "3.5.1"
)

enablePlugins(JavaAppPackaging)
