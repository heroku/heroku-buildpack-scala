import sbt._
import Keys._

object HerokuBuildpackPlugin extends Plugin {
  override def settings = Seq(
    sources in doc in Compile := List(),
    publishArtifact in packageDoc := false,
    publishArtifact in packageSrc := false
  )
}
