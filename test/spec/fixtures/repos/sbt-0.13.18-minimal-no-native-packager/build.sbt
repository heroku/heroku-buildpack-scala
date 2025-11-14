name := "sbt-0.13.18-minimal-no-native-packager"

scalaVersion := "2.13.17"

libraryDependencies ++= Seq(
	"dev.zio" %% "zio-http" % "3.5.1"
)

val stage = taskKey[Unit]("Stage task")

stage := {
  (compile in Compile).value
}
