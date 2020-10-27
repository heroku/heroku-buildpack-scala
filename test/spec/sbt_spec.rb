require_relative "spec_helper"

describe "Sbt" do
  it "should not download pre-cached dependencies" do
    new_default_hatchet_runner("sbt-minimal-scala-sample").tap do |app|
      app.before_deploy do
        set_java_version(DEFAULT_OPENJDK_VERSION)
      end

      app.deploy do
        expect(app.output).to include("Running: sbt compile stage")
        expect(app.output).to include("Priming Ivy cache")
        expect(app.output).not_to include("downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt")
        expect(app.output).not_to include("Main Scala API documentation to")
        expect(app.output).to include("[info] Done packaging.")

        app.commit!
        app.push!

        expect(app.output).to include("Running: sbt compile stage")
        expect(app.output).to include("[success]")
      end
    end
  end

  it "should run sbt-clean" do
    new_default_hatchet_runner("sbt-minimal-scala-sample").tap do |app|
      app.before_deploy do
        set_java_version(DEFAULT_OPENJDK_VERSION)
        app.set_config("SBT_CLEAN" => "true")
      end

      app.deploy do
        expect(app.output).to match("Running: sbt clean compile stage")
      end
    end
  end

  it "should work with sbt 1.0" do
    new_default_hatchet_runner("sbt-one-example").tap do |app|
      app.deploy do
        expect(app.output).to include("Running: sbt compile stage")
        expect(app.output).to include("https://repo.scala-sbt.org/scalasbt/maven-releases/org/scala-sbt/sbt-launch/1.0.0")
        expect(app.output).not_to include("Main Scala API documentation to")
        expect(app.output).to include("[info] Done packaging.")
      end
    end
  end
end
