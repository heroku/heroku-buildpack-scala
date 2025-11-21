import sbt._
import Keys._

object HerokuBuildpackPlugin extends Plugin {
  override def settings = Seq(
    sources in doc in Compile := List(),
    publishArtifact in packageDoc := false,
    publishArtifact in packageSrc := false,

    // sbt will output the following when run in batch mode:
    // > Executing in batch mode. For better performance use sbt's shell
    //
    // This might be confusing to users of the buildpack and is not an actionable warning for them. This key disables
    // that warning globally.
    suppressSbtShellNotification := true
  )
}
