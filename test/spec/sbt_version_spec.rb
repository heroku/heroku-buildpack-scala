# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt version warnings' do
  it 'shows warning for sbt 0.13.18' do
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

  it 'shows error for sbt versions older than 0.13.18' do
    new_default_hatchet_runner('sbt-0.13.17-minimal-with-native-packager', allow_failure: true).tap do |app|
      app.deploy do
        expect(app).not_to be_deployed
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Error: Unsupported sbt version detected.
          remote:  !
          remote:  !     This buildpack does not support sbt 0.13.17. You are using an end-of-life
          remote:  !     version that no longer receives security updates or bug fixes. Support for
          remote:  !     sbt 0.x was ended by the upstream sbt project on November 30, 2018.
          remote:  !
          remote:  !     Additionally, this buildpack version is not compatible with sbt versions
          remote:  !     older than 0.13.18 and cannot build your application.
          remote:  !
          remote:  !     To continue, update project/build.properties to use at least sbt 0.13.18,
          remote:  !     or preferably upgrade to sbt 1.x for active support.
          remote:  !
          remote:  !     For more information:
          remote:  !     - https://web.archive.org/web/20210918065807/https://www.lightbend.com/blog/scala-sbt-127-patchnotes
          remote:  !
          remote:  !     Upgrade guide:
          remote:  !     - https://www.scala-sbt.org/1.x/docs/Migrating-from-sbt-013x.html
        OUTPUT
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

  it 'shows error for sbt 2.0.0' do
    new_default_hatchet_runner('sbt-2.0.0-minimal-with-native-packager', allow_failure: true).tap do |app|
      app.deploy do
        expect(app).not_to be_deployed
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Error: Unsupported sbt version detected.
          remote:  !
          remote:  !     This buildpack does not support sbt 2.0.0. Due to a bug in this version,
          remote:  !     global plugins are not executed, which are required by this buildpack.
          remote:  !     The bug was fixed in sbt 2.0.1.
          remote:  !
          remote:  !     To continue, update project/build.properties to use at least sbt 2.0.1:
          remote:  !
          remote:  !         sbt.version=2.0.1
        OUTPUT
      end
    end
  end

  it 'successfully builds an sbt 2.x app' do
    new_default_hatchet_runner('sbt-2.0.1-minimal-with-native-packager').tap do |app|
      app.deploy do
        expect(clean_output(app.output)).to eq(<<~OUTPUT)
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK $VERSION
          remote: -----> Downloading sbt launcher 2.0.1...
          remote: -----> Setting up sbt launcher...
          remote: -----> Running: sbt compile stage
          remote:        [info] [launcher] getting org.scala-sbt sbt 2.0.1  (this may take some time)...
          remote:        [info] [launcher] getting Scala 3.8.4 (for sbt)...
          remote:        [info] welcome to sbt 2.0.1 (Azul Systems, Inc. Java $VERSION)
          remote:        [info] loading global plugins from /tmp/codon/tmp/cache/sbt_global/plugins
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/target/out/jvm/scala-3.8.4/global-plugins/classes ...
          remote:        [info] done compiling
          remote:        [info] loading project definition from $BUILD_DIR/project
          remote:        [info] set current project to sbt-2.0.1-minimal-with-native-packager (in build file:$BUILD_DIR/)
          remote:        [warn] there are 10 keys that are not used by any other settings/tasks:
          remote:        [warn]#{'  '}
          remote:        [warn] * $BUILD_ID / Debian / executableScriptName
          remote:        [warn]   +- Debian / executableScriptName := (Linux / executableScriptName).value:89
          remote:        [warn] * $BUILD_ID / Debian / sourceDirectory
          remote:        [warn]   +- Debian / sourceDirectory := sourceDirectory.value:101
          remote:        [warn] * $BUILD_ID / Rpm / daemonStdoutLogFile
          remote:        [warn]   +- Rpm / daemonStdoutLogFile := Some(rpmDaemonLogFile.value):107
          remote:        [warn] * $BUILD_ID / Rpm / executableScriptName
          remote:        [warn]   +- Rpm / executableScriptName := (Linux / executableScriptName).value:105
          remote:        [warn] * $BUILD_ID / Rpm / name
          remote:        [warn]   +- Rpm / name := (Linux / name).value:103
          remote:        [warn] * $BUILD_ID / Rpm / sourceDirectory
          remote:        [warn]   +- Rpm / sourceDirectory := sourceDirectory.value:119
          remote:        [warn] * $BUILD_ID / Universal / executableScriptName
          remote:        [warn]   +- Universal / executableScriptName := executableScriptName.value:73
          remote:        [warn] * $BUILD_ID / Universal-docs / name
          remote:        [warn]   +- UniversalDocs / name := (Universal / name).value:69
          remote:        [warn] * $BUILD_ID / Universal-src / name
          remote:        [warn]   +- UniversalSrc / name := (Universal / name).value:70
          remote:        [warn] * $BUILD_ID / rpmScriptletsDirectory
          remote:        [warn]   +- rpmScriptsDirectory := sourceDirectory.value / "rpm" / Names.Scriptlets:97
          remote:        [warn]#{'  '}
          remote:        [warn] note: a setting might still be used by a command; to exclude a key from this `lintUnused` check
          remote:        [warn] either append it to `Global / excludeLintKeys` or call .withRank(KeyRanks.Invisible) on the key
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/target/out/jvm/scala-2.13.17/sbt-2-0-1-minimal-with-native-packager/classes ...
          remote:        [info] done compiling
          remote:        [success] elapsed time: $DURATION, cache 25%, 3 disk cache hits, 9 onsite tasks
          remote:        [info] Wrote $BUILD_DIR/target/out/jvm/scala-2.13.17/sbt-2-0-1-minimal-with-native-packager/sbt-2-0-1-minimal-with-native-packager_2.13-0.1.0-SNAPSHOT.pom
          remote:        [success] elapsed time: $DURATION, cache 66%, 12 disk cache hits, 6 onsite tasks
          remote: -----> Collecting sbt plugin information
          remote: -----> Collecting dependency information
          remote: -----> Copying sbt and dependencies into slug for runtime use
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types -> (none)

          remote: -----> Compressing...
          remote:        Done: 106.8M
        OUTPUT
      end
    end
  end
end
