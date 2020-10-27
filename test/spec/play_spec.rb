require_relative "spec_helper"

describe "Play" do
  REPOS={
    "scala-getting-started" => "2.4",
    "play-2.3.x-scala-sample" => "2.3",
    "play-2.2.x-scala-sample" => "2.2"
  }

  REPOS.keys.each do |repo|
    context repo do
      it "should not download pre-cached dependencies" do
        new_default_hatchet_runner(repo).tap do |app|
          app.before_deploy do
            set_java_version(DEFAULT_OPENJDK_VERSION)
          end

          app.deploy do
            expect(app.output).to match("Running: sbt compile stage")
            expect(app.output).to match(/Priming Ivy cache \(Scala-2\.[0-9]{1,2}, Play-#{REPOS[repo]}\)/)
            #expect(app.output).not_to match("downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt")
            #expect(app.output).not_to match("downloading http://repo.typesafe.com/typesafe/releases/com/typesafe/play/play")
          end
        end
      end
    end
  end
end
