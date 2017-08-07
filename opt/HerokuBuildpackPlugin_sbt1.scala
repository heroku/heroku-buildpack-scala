import sbt._
import Keys._

object HerokuBuildpackPlugin extends AutoPlugin {
  override lazy val projectSettings = Seq(
    sources in doc in Compile := List(),
    publishArtifact in packageDoc := false,
    publishArtifact in packageSrc := false
  )
}
