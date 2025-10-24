# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt version warnings' do
  it 'shows warning for sbt 0.x versions' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.before_deploy do
        File.write('project/build.properties', "sbt.version=0.13.18\n")
      end

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
    new_default_hatchet_runner('sbt-one-example').tap do |app|
      app.deploy do
        expect(clean_output(app.output)).not_to include('Warning: Unsupported sbt version detected.')
        expect(app.output).to include('[success]')
      end
    end
  end

  it 'shows warning for sbt 2.x versions' do
    new_default_hatchet_runner('sbt-minimal-scala-sample').tap do |app|
      app.before_deploy do
        File.write('project/build.properties', "sbt.version=2.0.0-M1\n")
      end

      app.deploy do
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Warning: Unsupported sbt version detected.
          remote:  !     
          remote:  !     This buildpack does not support sbt 2.x yet. You are using sbt 2.0.0-M1.
          remote:  !     Note that sbt 2.x is still in development.
          remote:  !     
          remote:  !     Please use sbt 1.x for stable, production deployments.
          remote:  !     
          remote:  !     The buildpack will attempt to build your application, but compatibility
          remote:  !     is not guaranteed and may break at any time.
        OUTPUT
      end
    end
  end
end
