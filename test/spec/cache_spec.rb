# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Scala buildpack' do
  it 'caches compiled artifacts between builds' do
    new_default_hatchet_runner('sbt-0.11.7-play-3.x-scala-2.13.x').tap do |app|
      app.deploy do
        # First build should compile everything from scratch
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK 21.0.[0-9]+
          remote: -----> Running: sbt compile stage
          remote: Downloading sbt launcher for 1.11.7:
          remote:   From  https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.11.7/sbt-launch-1.11.7.jar
          remote:     To  /tmp/scala_buildpack_build_dir/.sbt_home/launchers/1.11.7/sbt-launch.jar
          remote: Downloading sbt launcher 1.11.7 md5 hash:
          remote:   From  https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/1.11.7/sbt-launch-1.11.7.jar.md5
          remote:     To  /tmp/scala_buildpack_build_dir/.sbt_home/launchers/1.11.7/sbt-launch.jar.md5
          remote:        /tmp/scala_buildpack_build_dir/.sbt_home/launchers/1.11.7/sbt-launch.jar: OK
          remote: \\[info\\] \\[launcher\\] getting org.scala-sbt sbt 1.11.7  \\(this may take some time\\)...
          remote: \\[info\\] \\[launcher\\] getting Scala 2.12.20 \\(for sbt\\)...
          remote:        \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
          remote:        \\[info\\] loading global plugins from /tmp/scala_buildpack_build_dir/.sbt_home/plugins
          remote:        \\[info\\] compiling 1 Scala source to /tmp/scala_buildpack_build_dir/.sbt_home/plugins/target/scala-2.12/sbt-1.0/classes ...
          remote:        \\[info\\] Non-compiled module 'compiler-bridge_2.12' for Scala 2.12.20. Compiling...
          remote:        \\[info\\]   Compilation completed in .*s.
          remote:        \\[info\\] done compiling
          remote:        \\[info\\] loading settings for project scala_buildpack_build_dir-build from plugins.sbt...
          remote:        \\[info\\] loading project definition from /tmp/scala_buildpack_build_dir/project
          remote:        \\[info\\] loading settings for project root from build.sbt...
          remote:        \\[info\\]   __              __
          remote:        \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
          remote:        \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
          remote:        \\[info\\]    / /  / /_/ // // /_/ // /_/ /
          remote:        \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
          remote:        \\[info\\]       /_/               /____/
          remote:        \\[info\\]
          remote:        \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
          remote:        \\[info\\]
          remote:        \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
          remote:        \\[info\\] https://www.playframework.com/sponsors
          remote:        \\[info\\]
          remote:        \\[info\\] Executing in batch mode. For better performance use sbt's shell
          remote:        \\[info\\] compiling 7 Scala sources and 1 Java source to /tmp/scala_buildpack_build_dir/target/scala-2.13/classes ...
          remote:        \\[info\\] done compiling
          remote:        \\[success\\] Total time: .* s, completed .*
          remote:        \\[info\\] Wrote /tmp/scala_buildpack_build_dir/target/scala-2.13/sbt-0-11-7-play-3-x-scala-2-13-x_2.13-1.0-SNAPSHOT.pom
          remote:        \\[success\\] Total time: .*
          remote: -----> Collecting dependency information
          remote: -----> Dropping ivy cache from the slug
          remote: -----> Dropping sbt boot dir from the slug
          remote: -----> Dropping sbt cache dir from the slug
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types     -> \\(none\\)
          remote:        Default types for buildpack -> web
          remote:
          remote: -----> Compressing...
        REGEX

        app.commit!
        app.push!

        # Second build should use cached artifacts and doesn't recompile previously compiled application files
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Scala app detected
          remote: -----> Installing Azul Zulu OpenJDK 21.0.[0-9]+
          remote: -----> Running: sbt compile stage
          remote:        \\[info\\] welcome to sbt 1.11.7 \\(Azul Systems, Inc. Java 21.0.[0-9]+\\)
          remote:        \\[info\\] loading global plugins from /tmp/scala_buildpack_build_dir/.sbt_home/plugins
          remote:        \\[info\\] loading settings for project scala_buildpack_build_dir-build from plugins.sbt...
          remote:        \\[info\\] loading project definition from /tmp/scala_buildpack_build_dir/project
          remote:        \\[info\\] loading settings for project root from build.sbt...
          remote:        \\[info\\]   __              __
          remote:        \\[info\\]   \\\\ \\\\     ____   / /____ _ __  __
          remote:        \\[info\\]    \\\\ \\\\   / __ \\\\ / // __ `// / / /
          remote:        \\[info\\]    / /  / /_/ // // /_/ // /_/ /
          remote:        \\[info\\]   /_/  / .___//_/ \\\\__,_/ \\\\__, /
          remote:        \\[info\\]       /_/               /____/
          remote:        \\[info\\]
          remote:        \\[info\\] Version 3.0.9 running Java 21.0.[0-9]+
          remote:        \\[info\\]
          remote:        \\[info\\] Play is run entirely by the community. Please consider contributing and/or donating:
          remote:        \\[info\\] https://www.playframework.com/sponsors
          remote:        \\[info\\]
          remote:        \\[info\\] Executing in batch mode. For better performance use sbt's shell
          remote:        \\[success\\] Total time: .* s, completed .*
          remote:        \\[info\\] Wrote /tmp/scala_buildpack_build_dir/target/scala-2.13/sbt-0-11-7-play-3-x-scala-2-13-x_2.13-1.0-SNAPSHOT.pom
          remote:        \\[success\\] Total time: .*
          remote: -----> Collecting dependency information
          remote: -----> Dropping ivy cache from the slug
          remote: -----> Dropping sbt boot dir from the slug
          remote: -----> Dropping sbt cache dir from the slug
          remote: -----> Dropping compilation artifacts from the slug
          remote: -----> Discovering process types
          remote:        Procfile declares types     -> \\(none\\)
          remote:        Default types for buildpack -> web
          remote:
          remote: -----> Compressing...
        REGEX
      end
    end
  end
end
