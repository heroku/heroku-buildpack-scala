require_relative 'spec_helper'

describe "Lift" do
  it "should not download pre-cached dependencies" do
    Hatchet::Runner.new("lift-2.5-sample").deploy do |app|
      # expect(app.output).to match("Running: sbt update")
      expect(app.output).to match("Running: sbt compile stage")
      expect(app.output).not_to match(/Priming Ivy cache/)

      expect(app.output).to match("downloading http://repo1.maven.org/maven2/com/github/jsimone/webapp-runner")

      expect(successful_body(app)).to match("Welcome, you now have a working Lift installation")
    end
  end
end
