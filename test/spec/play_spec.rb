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
          app.deploy do
            expect(app.output).to match("Running: sbt compile stage")
          end
        end
      end
    end
  end
end
