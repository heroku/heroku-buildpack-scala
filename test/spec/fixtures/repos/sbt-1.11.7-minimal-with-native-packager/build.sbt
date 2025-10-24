name := "sbt-1.11.7-minimal-with-native-packager"

scalaVersion := "2.13.17"

libraryDependencies ++= Seq(
	"dev.zio" %% "zio-http" % "3.5.1"
)

enablePlugins(JavaAppPackaging)
