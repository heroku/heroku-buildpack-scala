lazy val root = (project in file("."))
  .aggregate(subproject)
  .settings(
    name := "sbt-1.11.7-multi-project-root"
  )

lazy val subproject = (project in file("subproject"))
  .enablePlugins(JavaAppPackaging)
  .settings(
    name := "subproject",
    scalaVersion := "2.13.17",
    libraryDependencies ++= Seq(
      "dev.zio" %% "zio-http" % "3.5.1"
    )
  )