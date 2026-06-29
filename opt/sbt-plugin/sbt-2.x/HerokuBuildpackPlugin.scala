import sbt._
import sbt.Keys._

object HerokuBuildpackPlugin extends AutoPlugin {
  override def trigger = allRequirements

  override lazy val projectSettings = Seq(
    Compile / doc / sources := List(),
    packageDoc / publishArtifact := false,
    packageSrc / publishArtifact := false
  )

  override lazy val globalSettings = Seq(
    // sbt will output the following when run in batch mode:
    // > Executing in batch mode. For better performance use sbt's shell
    //
    // This might be confusing to users of the buildpack and is not an actionable warning for them. This key disables
    // that warning globally.
    //
    // See: https://www.scala-sbt.org/1.x/docs/Running.html#Batch+mode
    //
    // KeyRanks.Invisible is required to disable warnings by sbt's internal linter for unused keys which yields a
    // false-positive in the case here.
    suppressSbtShellNotification.withRank(KeyRanks.Invisible) := true,
  )
}
