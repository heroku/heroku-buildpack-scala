# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Sbt multi-project builds' do
  it 'applies project prefix to all tasks when SBT_PROJECT is set' do
    new_default_hatchet_runner('sbt-1.11.7-multi-project-with-native-packager').tap do |app|
      app.before_deploy do
        app.set_config('SBT_PROJECT' => 'subproject')
      end

      app.deploy do
        # Verify build output
        expect(clean_output(app.output)).to eq(<<~OUTPUT)
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK $VERSION
          remote: -----> Downloading sbt launcher 1.11.7...
          remote: -----> Setting up sbt launcher...
          remote: -----> Running: sbt subproject/compile subproject/stage
          remote:        [info] [launcher] getting org.scala-sbt sbt 1.11.7  (this may take some time)...
          remote:        [info] [launcher] getting Scala 2.12.20 (for sbt)...
          remote:        [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          remote:        [info] loading global plugins from /tmp/codon/tmp/cache/sbt_global/plugins
          remote:        [info] compiling 1 Scala source to /tmp/codon/tmp/cache/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
          remote:        [info] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
          remote:        [info]   Compilation completed in $DURATION.
          remote:        [info] done compiling
          remote:        [info] loading settings for project $BUILD_ID-build from plugins.sbt...
          remote:        [info] loading project definition from $BUILD_DIR/project
          remote:        [info] loading settings for project root from build.sbt...
          remote:        [info] set current project to sbt-1.11.7-multi-project-root (in build file:$BUILD_DIR/)
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/subproject/target/scala-2.13/classes ...
          remote:        [info] done compiling
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote:        [info] Wrote $BUILD_DIR/subproject/target/scala-2.13/subproject_2.13-0.1.0-SNAPSHOT.pom
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote: -----> Collecting sbt plugin information
          remote: -----> Collecting dependency information
          remote: -----> Copying sbt and dependencies into slug for runtime use
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types     -> (none)
          remote:        Default types for buildpack -> web
          remote:
          remote: -----> Compressing...
          remote:        Done: $SIZE
        OUTPUT

        # Verify app responds to HTTP requests
        response = Excon.get("#{app.platform_api.app.info(app.name)['web_url']}", expects: [200])
        expect(response.body).to eq('Hello from Scala multi-project!')
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
        # Verify build output includes the clean task
        expect(clean_output(app.output)).to eq(<<~OUTPUT)
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK $VERSION
          remote: -----> Downloading sbt launcher 1.11.7...
          remote: -----> Setting up sbt launcher...
          remote: -----> Running: sbt subproject/clean subproject/compile subproject/stage
          remote:        [info] [launcher] getting org.scala-sbt sbt 1.11.7  (this may take some time)...
          remote:        [info] [launcher] getting Scala 2.12.20 (for sbt)...
          remote:        [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          remote:        [info] loading global plugins from /tmp/codon/tmp/cache/sbt_global/plugins
          remote:        [info] compiling 1 Scala source to /tmp/codon/tmp/cache/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
          remote:        [info] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
          remote:        [info]   Compilation completed in $DURATION.
          remote:        [info] done compiling
          remote:        [info] loading settings for project $BUILD_ID-build from plugins.sbt...
          remote:        [info] loading project definition from $BUILD_DIR/project
          remote:        [info] loading settings for project root from build.sbt...
          remote:        [info] set current project to sbt-1.11.7-multi-project-root (in build file:$BUILD_DIR/)
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote:        [info] compiling 1 Scala source to $BUILD_DIR/subproject/target/scala-2.13/classes ...
          remote:        [info] done compiling
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote:        [info] Wrote $BUILD_DIR/subproject/target/scala-2.13/subproject_2.13-0.1.0-SNAPSHOT.pom
          remote:        [success] Total time: $DURATION, completed $DATETIME
          remote: -----> Collecting sbt plugin information
          remote: -----> Collecting dependency information
          remote: -----> Copying sbt and dependencies into slug for runtime use
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types     -> (none)
          remote:        Default types for buildpack -> web
          remote:
          remote: -----> Compressing...
          remote:        Done: $SIZE
        OUTPUT

        # Verify app responds to HTTP requests
        response = Excon.get("#{app.platform_api.app.info(app.name)['web_url']}", expects: [200])
        expect(response.body).to eq('Hello from Scala multi-project!')
      end
    end
  end
end