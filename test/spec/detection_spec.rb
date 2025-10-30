# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Scala buildpack detection' do
  it 'shows helpful error message when no sbt project files are found' do
    app = Hatchet::Runner.new('non-sbt-app', allow_failure: true)
    app.deploy do
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote:  !     Error: Your app is configured to use the Scala buildpack,
        remote:  !     but we couldn't find any supported sbt project files.
        remote:  !
        remote:  !     The Scala buildpack requires a 'build.sbt' or other .sbt file
        remote:  !     in the root directory of your source code.
        remote:  !
        remote:  !     IMPORTANT: If your project uses a different build tool:
        remote:  !     - For Maven projects, use the heroku/java buildpack instead
        remote:  !     - For Gradle projects, use the heroku/gradle buildpack instead
        remote:  !
        remote:  !     Currently the root directory of your app contains:
        remote:  !
        remote:  !     README.md
        remote:  !
        remote:  !     If your app already has sbt files, check that they:
        remote:  !
        remote:  !     1. Are in the correct directory (see requirements above).
        remote:  !     2. Have the correct spelling (the filenames are case-sensitive).
        remote:  !     3. Aren't listed in '.gitignore' or '.slugignore'.
        remote:  !     4. Have been added to the Git repository using 'git add --all'
        remote:  !        and then committed using 'git commit'.
        remote:  !
        remote:  !     For help with using sbt on Heroku, see:
        remote:  !     https://devcenter.heroku.com/articles/scala-support
      OUTPUT
    end
  end
end
