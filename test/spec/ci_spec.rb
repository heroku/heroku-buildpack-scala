# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Scala buildpack' do
  it 'runs tests on Heroku CI' do
    new_default_hatchet_runner('sbt-1.11.7-play-3.x-scala-2.13.x').tap do |app|
      app.run_ci do |test_run|
        # First CI run should build from scratch
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
        -----> Scala app detected
        -----> Installing Azul Zulu OpenJDK 21.0.[0-9]+
        -----> Running: sbt update
        Downloading sbt launcher for 1.11.7:
          From  https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.11.7/sbt-launch-1.11.7.jar
            To  /app/.sbt_home/launchers/1.11.7/sbt-launch.jar
        Downloading sbt launcher 1.11.7 md5 hash:
          From  https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.11.7/sbt-launch-1.11.7.jar.md5
            To  /app/.sbt_home/launchers/1.11.7/sbt-launch.jar.md5
               /app/.sbt_home/launchers/1.11.7/sbt-launch.jar: OK
        \\[info\\] \\[launcher\\] getting org.scala-sbt sbt 1.11.7  \\(this may take some time\\)...
        \\[info\\] \\[launcher\\] getting Scala 2.12.20 \\(for sbt\\)...
               \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
               \\[info\\] loading global plugins from .*/plugins
               \\[info\\] compiling 1 Scala source to .* ...
               \\[info\\] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
               \\[info\\]   Compilation completed in .*s.
               \\[info\\] done compiling
               \\[info\\] loading project definition from /app/project/project
               \\[info\\] loading settings for project app-build from ._plugins.sbt, plugins.sbt...
               \\[info\\] loading project definition from /app/project
               \\[info\\] loading settings for project root from ._build.sbt, build.sbt...
               \\[info\\]   __              __
               \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
               \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
               \\[info\\]    / /  / /_/ // // /_/ // /_/ /
               \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
               \\[info\\]       /_/               /____/
               \\[info\\]
               \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
               \\[info\\]
               \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
               \\[info\\] https://www.playframework.com/sponsors
               \\[info\\]
               \\[success\\] Total time: .* s, completed .*
        -----> Collecting sbt plugin information
        -----> Collecting dependency information
        -----> No test-setup command provided. Skipping.
        -----> Running Scala buildpack tests...
        Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8 -XX:MaxRAM=2684354560 -XX:MaxRAMPercentage=80.0
        \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
        \\[info\\] loading global plugins from .*/plugins
        \\[info\\] loading project definition from /app/project/project
        \\[info\\] loading settings for project app-build from ._plugins.sbt, plugins.sbt...
        \\[info\\] loading project definition from /app/project
        \\[info\\] loading settings for project root from ._build.sbt, build.sbt...
        \\[info\\]   __              __
        \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
        \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
        \\[info\\]    / /  / /_/ // // /_/ // /_/ /
        \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
        \\[info\\]       /_/               /____/
        \\[info\\]
        \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
        \\[info\\]
        \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
        \\[info\\] https://www.playframework.com/sponsors
        \\[info\\]
        \\[info\\] compiling 7 Scala sources and 1 Java source to /app/target/scala-2.13/classes ...
        \\[info\\] done compiling
        \\[success\\] Total time: .*, completed .*
        -----> Scala buildpack tests completed successfully
      REGEX

      test_run.run_again

      # Second CI run should use cached artifacts
      expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
        -----> Scala app detected
        -----> Installing Azul Zulu OpenJDK 21.0.[0-9]+
        -----> Running: sbt update
               \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
               \\[info\\] loading global plugins from .*/plugins
               \\[info\\] loading project definition from /app/project/project
               \\[info\\] loading settings for project app-build from ._plugins.sbt, plugins.sbt...
               \\[info\\] loading project definition from /app/project
               \\[info\\] loading settings for project root from ._build.sbt, build.sbt...
               \\[info\\]   __              __
               \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
               \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
               \\[info\\]    / /  / /_/ // // /_/ // /_/ /
               \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
               \\[info\\]       /_/               /____/
               \\[info\\]
               \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
               \\[info\\]
               \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
               \\[info\\] https://www.playframework.com/sponsors
               \\[info\\]
               \\[success\\] Total time: .* s, completed .*
        -----> Collecting sbt plugin information
        -----> Collecting dependency information
        -----> No test-setup command provided. Skipping.
        -----> Running Scala buildpack tests...
        Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8 -XX:MaxRAM=2684354560 -XX:MaxRAMPercentage=80.0
        \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
        \\[info\\] loading global plugins from .*/plugins
        \\[info\\] loading project definition from /app/project/project
        \\[info\\] loading settings for project app-build from ._plugins.sbt, plugins.sbt...
        \\[info\\] loading project definition from /app/project
        \\[info\\] loading settings for project root from ._build.sbt, build.sbt...
        \\[info\\]   __              __
        \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
        \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
        \\[info\\]    / /  / /_/ // // /_/ // /_/ /
        \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
        \\[info\\]       /_/               /____/
        \\[info\\]
        \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
        \\[info\\]
        \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
        \\[info\\] https://www.playframework.com/sponsors
        \\[info\\]
        \\[info\\] compiling 7 Scala sources and 1 Java source to /app/target/scala-2.13/classes ...
        \\[info\\] done compiling
        \\[success\\] Total time: .* s, completed .*
        -----> Scala buildpack tests completed successfully
      REGEX
      end
    end
  end
end
