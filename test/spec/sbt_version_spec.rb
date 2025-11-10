# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt version warnings' do
  it 'shows warning for sbt 0.x versions' do
    new_default_hatchet_runner('sbt-0.13.18-minimal-with-native-packager').tap do |app|
      app.deploy do
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Warning: Unsupported sbt version detected.
          remote:  !
          remote:  !     This buildpack does not officially support sbt 0.13.18. You are using
          remote:  !     an end-of-life version that no longer receives security updates or bug fixes.
          remote:  !     Support for sbt 0.x was ended by the upstream sbt project on November 30, 2018.
          remote:  !
          remote:  !     Please upgrade to sbt 1.x for active support.
          remote:  !
          remote:  !     The buildpack will attempt to build your application, but compatibility
          remote:  !     is not guaranteed and may break at any time.
          remote:  !
          remote:  !     For more information:
          remote:  !     - https://web.archive.org/web/20210918065807/https://www.lightbend.com/blog/scala-sbt-127-patchnotes
          remote:  !
          remote:  !     Upgrade guide:
          remote:  !     - https://www.scala-sbt.org/1.x/docs/Migrating-from-sbt-013x.html
        OUTPUT

        expect(app.output).to include('Running: sbt compile stage')
        expect(app.output).to include('[info] Done packaging.')
        expect(app.output).to include('[success]')
      end
    end
  end

  it 'does not show warning for sbt 1.x versions' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.deploy do
        expect(clean_output(app.output)).not_to include('Warning: Unsupported sbt version detected.')
        expect(app.output).to include('[success]')
      end
    end
  end

  it 'shows error for sbt 2.x versions' do
    new_default_hatchet_runner('sbt-2.0.0-RC6-minimal-with-native-packager', allow_failure: true).tap do |app|
      app.deploy do
        expect(app).not_to be_deployed
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Error: Unsupported sbt version detected.
          remote:  !
          remote:  !     This buildpack does not currently support sbt 2.x. You are using sbt 2.0.0-RC6.
          remote:  !
          remote:  !     Support for sbt 2.x will be added in a future buildpack release. In the
          remote:  !     meantime, please use the latest stable sbt 1.x version for your deployments.
          remote:  !
          remote:  !     To continue, update project/build.properties to use sbt 1.x.
          remote:  !
          remote:  !     For more information:
          remote:  !     - Latest sbt 1.x releases: https://github.com/sbt/sbt/releases
          remote:  !     - sbt 2.x changes: https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html
        OUTPUT
      end
    end
  end

  it 'shows error when sbt version cannot be determined' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager', allow_failure: true).tap do |app|
      app.before_deploy do
        # Remove contents of project/build.properties
        File.write('project/build.properties', '')
      end

      app.deploy do
        expect(app).not_to be_deployed
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Error: sbt version cannot be determined.
          remote:  !
          remote:  !     As part of your build definition you must specify the version of sbt that
          remote:  !     your build uses. This ensures consistent results across different environments.
          remote:  !
          remote:  !     To fix this issue, create a file named project/build.properties that specifies
          remote:  !     the sbt version as follows:
          remote:  !
          remote:  !         sbt.version=1.11.7
          remote:  !
          remote:  !     For more information, see:
          remote:  !     https://www.scala-sbt.org/1.x/docs/Basic-Def.html#Specifying+the+sbt+version
        OUTPUT
      end
    end
  end
end
