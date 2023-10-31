import sbt._
import sbt.Keys._

object HerokuBuildpackPlugin extends AutoPlugin {
  override def trigger = allRequirements

  override lazy val projectSettings = Seq(
    Compile / doc / sources := List(),
    packageDoc / publishArtifact := false,
    packageSrc / publishArtifact := false
  )
}
