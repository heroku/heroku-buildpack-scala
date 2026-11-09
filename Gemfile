# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.3', '< 4.1'

group :test, :development do
  gem 'heroku_hatchet'
  gem 'java-properties'
  # Required by threaded (a heroku_hatchet dependency) since Ruby 4.0 no longer ships it as a default gem
  gem 'logger'
  gem 'parallel_split_test'
  gem 'rspec-expectations'
  gem 'rspec-retry'
  gem 'rubocop'
  gem 'rubocop-rspec'
end
