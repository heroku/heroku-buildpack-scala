name := "sbt-1.11.7-minimal-no-native-packager"

scalaVersion := "2.13.17"

libraryDependencies ++= Seq(
	"dev.zio" %% "zio-http" % "3.5.1"
)

val stage = taskKey[Unit]("Stage task")

stage := {
  (Compile / compile).value
}
