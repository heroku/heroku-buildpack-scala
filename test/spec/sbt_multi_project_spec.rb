# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt multi-project builds' do
  it 'applies project prefix to all tasks when SBT_PROJECT is set' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.before_deploy do
        # Convert to a multi-project build
        File.write('build.sbt', <<~BUILD_SBT)
          lazy val root = (project in file("."))
            .aggregate(subproject)
            .settings(
              name := "root-project"
            )

          lazy val subproject = (project in file("subproject"))
            .settings(
              name := "subproject",
              version := "0.1.0-SNAPSHOT",
              scalaVersion := "2.13.15"
            )
        BUILD_SBT

        # Move existing source to subproject
        FileUtils.mkdir_p('subproject')
        FileUtils.mv('src', 'subproject/')

        # Set SBT_PROJECT to build only the subproject
        app.set_config('SBT_PROJECT' => 'subproject')
      end

      app.deploy do
        # Verify that all tasks use the project prefix
        expect(app.output).to match('Running: sbt subproject/compile subproject/stage')
      end
    end
  end

  it 'applies project prefix to custom tasks when SBT_PROJECT and SBT_TASKS are both set' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.before_deploy do
        # Convert to a multi-project build
        File.write('build.sbt', <<~BUILD_SBT)
          lazy val root = (project in file("."))
            .aggregate(subproject)
            .settings(
              name := "root-project"
            )

          lazy val subproject = (project in file("subproject"))
            .settings(
              name := "subproject",
              version := "0.1.0-SNAPSHOT",
              scalaVersion := "2.13.15"
            )
        BUILD_SBT

        # Move existing source to subproject
        FileUtils.mkdir_p('subproject')
        FileUtils.mv('src', 'subproject/')

        # Set both SBT_PROJECT and custom SBT_TASKS
        app.set_config('SBT_PROJECT' => 'subproject')
        app.set_config('SBT_TASKS' => 'clean compile stage')
      end

      app.deploy do
        # Verify that the project prefix is applied to all custom tasks
        expect(app.output).to match('Running: sbt subproject/clean subproject/compile subproject/stage')
      end
    end
  end
end