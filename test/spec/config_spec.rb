# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Scala buildpack configuration' do
  it 'supports environment variable configuration without warning' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
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
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
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

  it 'shows deprecation warning when using SBT_PRE_TASKS' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_PRE_TASKS' => 'clean')
      end

      app.deploy do
        expect(clean_output(app.output)).to include('Running: sbt clean compile stage')
        expect(clean_output(app.output)).to include(<<~WARNING)
          remote:  !     Warning: SBT_PRE_TASKS is deprecated.
          remote:  !
          remote:  !     The SBT_PRE_TASKS configuration option is deprecated and will be removed
          remote:  !     in a future buildpack version.
          remote:  !
          remote:  !     Instead of using SBT_PRE_TASKS, add your tasks directly to SBT_TASKS:
          remote:  !
          remote:  !         heroku config:set SBT_TASKS="clean compile stage"
          remote:  !
          remote:  !     The buildpack will continue to use your SBT_PRE_TASKS configuration for now.
        WARNING
      end
    end
  end

  it 'sanitizes SBT_OPTS by removing -J prefix from arguments' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_OPTS' => '-J-Xmx1G -J-Xms512m -Dfoo=bar')
      end

      app.deploy do
        expect(app).to be_deployed
        expect(clean_output(app.output)).to include('Running: sbt compile stage')
      end
    end
  end
end
