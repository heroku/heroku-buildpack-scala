# frozen_string_literal: true

require_relative 'spec_helper'

REPOS = {
  'scala-getting-started' => '2.4',
  'play-2.3.x-scala-sample' => '2.3',
  'play-2.2.x-scala-sample' => '2.2',
}.freeze

describe 'Play' do
  REPOS.each_key do |repo|
    context repo do
      it 'does not download pre-cached dependencies' do
        new_default_hatchet_runner(repo).tap do |app|
          app.deploy do
            expect(app.output).to match('Running: sbt compile stage')
          end
        end
      end
    end
  end
end
