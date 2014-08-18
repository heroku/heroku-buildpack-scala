require_relative 'spec_helper'

describe "Sbt" do
  it "should not download pre-cached dependencies" do
    Hatchet::Runner.new("sbt-minimal-scala-sample").deploy do |app|
      expect(app.output).to match("Running: sbt update")
      expect(app.output).to match("Running: sbt compile stage")
      expect(app.output).to match(/Priming Ivy cache/)
      expect(app.output).not_to match("downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt")
    end
  end

  it "should run sbt-clean" do
    app = Hatchet::Runner.new("sbt-minimal-scala-sample")
    app.setup!
    app.set_config("SBT_CLEAN" => "true")

    app.deploy do |app|
      expect(app.output).to match("Running: sbt clean compile stage")
    end
  end

  it "" do
    Hatchet::Runner.new("sbt-start-script-sample") do |app|
      expect(app.output).not_to match(/Priming Ivy cache/)
      expect(app.output).to match("Running: sbt compile stage")
    end
  end
end
