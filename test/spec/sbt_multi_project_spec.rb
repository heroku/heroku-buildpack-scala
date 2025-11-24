# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt multi-project builds' do
  it 'applies project prefix to all tasks when SBT_PROJECT is set' do
    new_default_hatchet_runner('sbt-1.11.7-multi-project-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_PROJECT' => 'subproject')
      end

      app.deploy do
        expect(app.output).to match('Running: sbt subproject/compile subproject/stage')
      end
    end
  end

  it 'applies project prefix to custom tasks when SBT_PROJECT and SBT_TASKS are both set' do
    new_default_hatchet_runner('sbt-1.11.7-multi-project-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_PROJECT' => 'subproject')
        app.set_config('SBT_TASKS' => 'clean compile stage')
      end

      app.deploy do
        expect(app.output).to match('Running: sbt subproject/clean subproject/compile subproject/stage')
      end
    end
  end
end
