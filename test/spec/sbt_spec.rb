# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt' do
  it 'does not download pre-cached dependencies' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.deploy do
        expect(app.output).to include('Running: sbt compile stage')
        expect(app.output).to include('Priming Ivy cache')
        expect(app.output).not_to include('downloading http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt')
        expect(app.output).not_to include('Main Scala API documentation to')
        expect(app.output).to include('[info] Done packaging.')

        app.commit!
        app.push!

        expect(app.output).to include('Running: sbt compile stage')
        expect(app.output).to include('[success]')
      end
    end
  end

  it 'runs sbt-clean' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.before_deploy do
        app.set_config('SBT_CLEAN' => 'true')
      end

      app.deploy do
        expect(app.output).to match('Running: sbt clean compile stage')
      end
    end
  end

  it 'works with sbt 1.1' do
    new_default_hatchet_runner('sbt-one-example').tap do |app|
      app.deploy do
        expect(app.output).to include('Running: sbt compile stage')
        expect(app.output).to include('https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.1.6')
        expect(app.output).not_to include('Main Scala API documentation to')
        expect(app.output).to include('[info] Done packaging.')
      end
    end
  end

  it 'rewrites PATH correctly when used with multiple buildpacks' do
    # When multiple buildpacks are used, earlier buildpacks (like heroku/jvm) may add
    # executables to PATH that reference APP_BUILD_DIR. When this buildpack moves the
    # build directory to a temp location, it must rewrite PATH to replace APP_BUILD_DIR
    # with the new BUILD_DIR. This test verifies that the PATH rewriting logic works
    # correctly by running heroku/jvm first (which adds java to PATH), then running
    # this buildpack which should successfully find and use that java executable.
    new_default_hatchet_runner('sbt-minimal-scala-sample', buildpacks: ['heroku/jvm', :default]).tap do |app|
      app.deploy do
        expect(app.output).to include('Running: sbt compile stage')
        expect(app.output).to include('[info] Done packaging.')
      end
    end
  end
end
