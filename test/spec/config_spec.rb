# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Scala buildpack configuration' do
  it 'supports environment variable configuration without warning' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.before_deploy do
        app.set_config('SBT_CLEAN' => 'true')
      end

      app.deploy do
        expect(clean_output(app.output)).to include('Running: sbt clean compile stage')
        expect(clean_output(app.output)).not_to include(
          'Warning: Configuring the Scala buildpack via system.properties is deprecated'
        )
      end
    end
  end

  it 'shows deprecation warning when using system.properties' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.before_deploy do
        File.write('system.properties', "#{File.read('system.properties')}\nsbt.clean=true\n")
      end

      app.deploy do
        expect(clean_output(app.output)).to include('Running: sbt clean compile stage')
        expect(clean_output(app.output)).to include(<<~WARNING)
          remote:  !     Warning: Configuring the Scala buildpack via system.properties is deprecated.
          remote:  !     
          remote:  !     You are using the sbt.clean property in system.properties, which is
          remote:  !     deprecated and will be removed in a future buildpack release.
          remote:  !     
          remote:  !     Please migrate to using the SBT_CLEAN environment variable instead.
          remote:  !     
          remote:  !     For more information on setting environment variables, see:
          remote:  !     https://devcenter.heroku.com/articles/config-vars
        WARNING
      end
    end
  end
end
