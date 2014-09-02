name := "heroku-buildpack-scala"

resolvers +=
  "rubygems-release" at "http://rubygems-proxy.torquebox.org/releases"

libraryDependencies ++= Seq(
  "rubygems" % "thor" % "0.15.4",
  "rubygems" % "rspec-retry" % "0.3.0",
  "rubygems" % "heroku_hatchet" % "1.3.4" excludeAll(ExclusionRule("rubygems", "thor")),
  "rubygems" % "rspec" % "3.0.0"
)

commands += Command.command("hatchet")((state:State) => {
  "gemExec hatchet install" ::
  "gemExec rspec" ::
  state
})
