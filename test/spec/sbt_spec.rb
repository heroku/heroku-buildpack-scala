# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt' do
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
end
