require_relative 'spec_helper'

describe "Sbt" do
  it "should not download pre-cached dependencies" do
    Hatchet::Runner.new("sbt-minimal-scala-sample").deploy do |app|
      expect(app.output).to include("Running: sbt compile stage")
      expect(app.output).to include("Priming Ivy cache")
      expect(app.output).not_to include("downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt")
      expect(app.output).not_to include("Main Scala API documentation to")
      expect(app.output).to include("[info] Done packaging.")

      `git commit -am "redeploy" --allow-empty`
      app.push!
      expect(app.output).to include("Running: sbt compile stage")
      expect(app.output).to include("[info] Done packaging.")
    end
  end

  it "should run sbt-clean" do
    app = Hatchet::Runner.new("sbt-minimal-scala-sample")
    init_app(app)
    app.set_config("SBT_CLEAN" => "true")

    app.deploy do |app|
      expect(app.output).to match("Running: sbt clean compile stage")
    end
  end

  it "not prime cache for sbt-start-script projects" do
    Hatchet::Runner.new("sbt-start-script-sample") do |app|
      # expect(app.output).to match("Running: sbt update")
      expect(app.output).not_to match(/Priming Ivy cache/)
      expect(app.output).to match("Running: sbt compile stage")
    end
  end
end
