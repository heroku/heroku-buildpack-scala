# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt' do
  it 'runs sbt-clean' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_CLEAN' => 'true')
      end

      app.deploy do
        expect(app.output).to match('Running: sbt clean compile stage')
      end
    end
  end

  it 'works when combined with other buildpacks' do
    # Regression test for https://github.com/heroku/heroku-buildpack-scala/issues/268
    # Verifies that this buildpack can successfully use executables added to PATH
    # by earlier buildpacks (like heroku/jvm).
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager',
                               buildpacks: ['heroku/jvm', :default]).tap do |app|
      app.deploy do
        expect(clean_output(app.output)).to eq(<<~OUTPUT)
          remote: -----> JVM Common app detected
          remote: -----> Installing Azul Zulu OpenJDK $VERSION
          remote: -----> Scala app detected
          remote: -----> Using provided JDK
          remote: -----> Downloading sbt launcher 1.11.7...
          remote: -----> Setting up sbt launcher...
          remote: -----> Running: sbt compile stage
          remote: [info] [launcher] getting org.scala-sbt sbt 1.11.7  (this may take some time)...
          remote: [info] [launcher] getting Scala 2.12.20 (for sbt)...
          remote:        [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          remote:        [info] loading global plugins from /tmp/codon/tmp/cache/sbt_global/plugins
          remote:        [info] compiling 1 Scala source to /tmp/codon/tmp/cache/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
          remote:        [info] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
          remote:        [info]   Compilation completed in $DURATION.
          remote:        [info] done compiling
          remote:        [info] loading settings for project $BUILD_ID-build from plugins.sbt...
          remote:        [info] loading project definition from $BUILD_DIR/project
          remote:        [info] loading settings for project $BUILD_ID from build.sbt...
          remote:        [info] set current project to sbt-1.11.7-minimal-with-native-packager (in build file:$BUILD_DIR/)
          remote:        [info] Executing in batch mode. For better performance use sbt's shell
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/target/scala-2.13/classes ...
          remote:        [info] done compiling
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote:        [info] Wrote $BUILD_DIR/target/scala-2.13/sbt-1-11-7-minimal-with-native-packager_2.13-0.1.0-SNAPSHOT.pom
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote: -----> Collecting dependency information
          remote: -----> Copying sbt and dependencies into slug for runtime use
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types     -> (none)
          remote:        Default types for buildpack -> web

          remote: -----> Compressing...
          remote:        Done: 106.5M
        OUTPUT
      end
    end
  end

  it 'fails the build when sbt compilation fails' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-with-native-packager', allow_failure: true).tap do |app|
      app.before_deploy do
        File.write('src/main/scala/com/heroku/App.scala', 'this will not compile')
      end

      app.deploy do
        expect(app).not_to be_deployed

        expect(clean_output(app.output)).to eq(<<~OUTPUT)
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK $VERSION
          remote: -----> Downloading sbt launcher 1.11.7...
          remote: -----> Setting up sbt launcher...
          remote: -----> Running: sbt compile stage
          remote: [info] [launcher] getting org.scala-sbt sbt 1.11.7  (this may take some time)...
          remote: [info] [launcher] getting Scala 2.12.20 (for sbt)...
          remote:        [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          remote:        [info] loading global plugins from /tmp/codon/tmp/cache/sbt_global/plugins
          remote:        [info] compiling 1 Scala source to /tmp/codon/tmp/cache/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
          remote:        [info] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
          remote:        [info]   Compilation completed in $DURATION.
          remote:        [info] done compiling
          remote:        [info] loading settings for project $BUILD_ID-build from plugins.sbt...
          remote:        [info] loading project definition from $BUILD_DIR/project
          remote:        [info] loading settings for project $BUILD_ID from build.sbt...
          remote:        [info] set current project to sbt-1.11.7-minimal-with-native-packager (in build file:$BUILD_DIR/)
          remote:        [info] Executing in batch mode. For better performance use sbt's shell
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/target/scala-2.13/classes ...
          remote:        [error] $BUILD_DIR/src/main/scala/com/heroku/App.scala:1:1: expected class or object definition
          remote:        [error] this will not compile
          remote:        [error] ^
          remote:        [error] one error found
          remote:        [error] (Compile / compileIncremental) Compilation failed
          remote:        [error] Total time: $DURATION, completed $DATETIME

          remote:  !     Failed to run sbt!
          remote:  !     We're sorry this build is failing. If you can't find the issue in application
          remote:  !     code, please submit a ticket so we can help: https://help.heroku.com
          remote:  !     You can also try reverting to the previous version of the buildpack by running:
          remote:  !     $ heroku buildpacks:set https://github.com/heroku/heroku-buildpack-scala#previous-version
          remote:  !
          remote:  !     Thanks,
          remote:  !     Heroku

          remote:  !     Push rejected, failed to compile Scala app.

          remote:  !     Push failed
        OUTPUT
      end
    end
  end
end
