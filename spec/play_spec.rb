require_relative 'spec_helper'

describe "Play" do

  REPOS={
    "play-2.3.x-scala-sample" => "2.3",
    "play-2.2.x-scala-sample" => "2.2",
    "play-2.1.x-scala-sample" => "2.1",
    "play-2.0.x-scala-sample" => "2.0",
    "play-2.3.x-java-sample" => "2.3",
    # "play-2.2.x-java-sample" => "2.2",
    #"play-2.1.x-java-sample" => "2.1",
    #"play-2.0.x-java-sample" => "2.0"
  }

  REPOS.keys.each do |repo|
    context repo do
      it "should not download pre-cached dependencies" do
        Hatchet::Runner.new(repo).deploy do |app|
          expect(app.output).to match("Running: sbt update")
          expect(app.output).to match("Running: sbt compile stage")
          expect(app.output).to match(/Priming Ivy cache \(Scala-2\.[0-9]{1,2}, Play-#{REPOS[repo]}\)/)
          #expect(app.output).not_to match("downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt")
          #expect(app.output).not_to match("downloading http://repo.typesafe.com/typesafe/releases/com/typesafe/play/play")
        end
      end
    end
  end
end
