# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Scala buildpack' do
  # Coursier stores artifacts by repository URL. Without sbt-native-packager, the buildpack copies the coursier
  # cache into the slug, which shows which hosts the build resolved artifacts from.
  it 'resolves Maven Central artifacts from the Google mirror by default' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-no-native-packager').tap do |app|
      app.deploy do
        cache_hosts = app.run('ls .sbt_home/.coursier/cache/https')

        expect(cache_hosts).to include('maven-central.storage-download.googleapis.com')
        expect(cache_hosts).not_to include('repo1.maven.org')
      end
    end
  end

  it 'resolves Maven Central artifacts from Maven Central when MAVEN_CENTRAL_MIRROR is false' do
    new_default_hatchet_runner('sbt-1.11.7-minimal-no-native-packager',
                               config: { MAVEN_CENTRAL_MIRROR: 'false' }).tap do |app|
      app.deploy do
        cache_hosts = app.run('ls .sbt_home/.coursier/cache/https')

        expect(cache_hosts).to include('repo1.maven.org')
        expect(cache_hosts).not_to include('maven-central.storage-download.googleapis.com')
      end
    end
  end
end
