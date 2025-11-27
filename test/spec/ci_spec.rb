# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Scala buildpack' do
  it 'runs tests on Heroku CI' do
    new_default_hatchet_runner('sbt-1.11.7-play-3.x-scala-2.13.x').tap do |app|
      app.run_ci do |test_run|
        # First CI run should build from scratch
        expect(clean_output(test_run.output)).to eq(<<~OUTPUT)
          -----> Scala app detected
          -----> Installing Azul Zulu OpenJDK $VERSION
          -----> Downloading sbt launcher 1.11.7...
          -----> Setting up sbt launcher...
          -----> Running: sbt update
                 [info] [launcher] getting org.scala-sbt sbt 1.11.7  (this may take some time)...
                 [info] [launcher] getting Scala 2.12.20 (for sbt)...
                 [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
                 [info] loading global plugins from $CACHE_DIR/sbt_global/plugins
                 [info] compiling 1 Scala source to $CACHE_DIR/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
                 [info] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
                 [info]   Compilation completed in $DURATION.
                 [info] done compiling
                 [info] loading settings for project app-build from plugins.sbt...
                 [info] loading project definition from /app/project
                 [info] loading settings for project root from build.sbt...
                 [info]   __              __
                 [info]   \\ \\     ____   / /____ _ __  __
                 [info]    \\ \\   / __ \\ / // __ `// / / /
                 [info]    / /  / /_/ // // /_/ // /_/ /
                 [info]   /_/  / .___//_/ \\__,_/ \\__, /
                 [info]       /_/               /____/
                 [info]
                 [info] Version 3.0.9 running Java $VERSION
                 [info]
                 [info] Play is run entirely by the community. Please consider contributing and/or donating:
                 [info] https://www.playframework.com/sponsors
                 [info]
                 [success] Total time: $DURATION, completed $DATETIME
          -----> Collecting sbt plugin information
          -----> Collecting dependency information
          -----> Copying sbt and dependencies into slug for runtime use
          -----> No test-setup command provided. Skipping.
          -----> Running Scala buildpack tests...
          Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8 -XX:MaxRAM=2684354560 -XX:MaxRAMPercentage=80.0
          [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          [info] loading global plugins from /app/.sbt_home/plugins
          [info] compiling 1 Scala source to /app/.sbt_home/plugins/target/scala-2.12/sbt-1.0/classes ...
          [info] done compiling
          [info] loading settings for project app-build from plugins.sbt...
          [info] loading project definition from /app/project
          [info] loading settings for project root from build.sbt...
          [info]   __              __
          [info]   \\ \\     ____   / /____ _ __  __
          [info]    \\ \\   / __ \\ / // __ `// / / /
          [info]    / /  / /_/ // // /_/ // /_/ /
          [info]   /_/  / .___//_/ \\__,_/ \\__, /
          [info]       /_/               /____/
          [info]
          [info] Version 3.0.9 running Java $VERSION
          [info]
          [info] Play is run entirely by the community. Please consider contributing and/or donating:
          [info] https://www.playframework.com/sponsors
          [info]
          [info] compiling 7 Scala sources and 1 Java source to /app/target/scala-2.13/classes ...
          [info] done compiling
          [success] Total time: $DURATION, completed $DATETIME
          -----> Scala buildpack tests completed successfully
        OUTPUT

        test_run.run_again

        # Second CI run should use cached artifacts
        expect(clean_output(test_run.output)).to eq(<<~OUTPUT)
          -----> Scala app detected
          -----> Installing Azul Zulu OpenJDK $VERSION
          -----> Setting up sbt launcher...
          -----> Running: sbt update
                 [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
                 [info] loading global plugins from $CACHE_DIR/sbt_global/plugins
                 [info] compiling 1 Scala source to $CACHE_DIR/sbt_global/plugins/target/scala-2.12/sbt-1.0/classes ...
                 [info] done compiling
                 [info] loading settings for project app-build from plugins.sbt...
                 [info] loading project definition from /app/project
                 [info] loading settings for project root from build.sbt...
                 [info]   __              __
                 [info]   \\ \\     ____   / /____ _ __  __
                 [info]    \\ \\   / __ \\ / // __ `// / / /
                 [info]    / /  / /_/ // // /_/ // /_/ /
                 [info]   /_/  / .___//_/ \\__,_/ \\__, /
                 [info]       /_/               /____/
                 [info]
                 [info] Version 3.0.9 running Java $VERSION
                 [info]
                 [info] Play is run entirely by the community. Please consider contributing and/or donating:
                 [info] https://www.playframework.com/sponsors
                 [info]
                 [success] Total time: $DURATION, completed $DATETIME
          -----> Collecting sbt plugin information
          -----> Collecting dependency information
          -----> Copying sbt and dependencies into slug for runtime use
          -----> No test-setup command provided. Skipping.
          -----> Running Scala buildpack tests...
          Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8 -XX:MaxRAM=2684354560 -XX:MaxRAMPercentage=80.0
          [info] welcome to sbt 1.11.7 (Azul Systems, Inc. Java $VERSION)
          [info] loading global plugins from /app/.sbt_home/plugins
          [info] compiling 1 Scala source to /app/.sbt_home/plugins/target/scala-2.12/sbt-1.0/classes ...
          [info] done compiling
          [info] loading settings for project app-build from plugins.sbt...
          [info] loading project definition from /app/project
          [info] loading settings for project root from build.sbt...
          [info]   __              __
          [info]   \\ \\     ____   / /____ _ __  __
          [info]    \\ \\   / __ \\ / // __ `// / / /
          [info]    / /  / /_/ // // /_/ // /_/ /
          [info]   /_/  / .___//_/ \\__,_/ \\__, /
          [info]       /_/               /____/
          [info]
          [info] Version 3.0.9 running Java $VERSION
          [info]
          [info] Play is run entirely by the community. Please consider contributing and/or donating:
          [info] https://www.playframework.com/sponsors
          [info]
          [info] compiling 7 Scala sources and 1 Java source to /app/target/scala-2.13/classes ...
          [info] done compiling
          [success] Total time: $DURATION, completed $DATETIME
          -----> Scala buildpack tests completed successfully
        OUTPUT
      end
    end
  end
end
