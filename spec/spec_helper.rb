require 'rspec/core'
require 'hatchet'
require 'fileutils'
require 'hatchet'
require 'rspec/retry'
require 'date'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.filter_run focused: true unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, focused: true
  config.full_backtrace      = true
  config.verbose_retry       = true # show retry status in spec process
  config.default_retry_count = 2 if ENV['CI'] # retry all tests that fail again

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  # config.mock_with :none
end

def git_repo
  "https://github.com/heroku/heroku-buildpack-scala.git"
end

def init_app(app)
  app.setup!
  unless ENV["HEROKU_TEST_STACK"].nil?
    app.platform_api.app.update(app.name, {"build_stack" => ENV["HEROKU_TEST_STACK"]})
  end
  unless ENV['JVM_COMMON_BUILDPACK'].nil? or ENV['JVM_COMMON_BUILDPACK'].empty?
    app.set_config("JVM_COMMON_BUILDPACK" => ENV['JVM_COMMON_BUILDPACK'])
    expect(app.get_config['JVM_COMMON_BUILDPACK']).to eq(ENV['JVM_COMMON_BUILDPACK'])
  end
end

def add_database(app, heroku)
  Hatchet::RETRIES.times.retry do
    heroku.post_addon(app.name, 'heroku-postgresql:hobby-dev')
    _, value = heroku.get_config_vars(app.name).body.detect {|key, value| key.match(/HEROKU_POSTGRESQL_[A-Z]+_URL/) }
    heroku.put_config_vars(app.name, 'DATABASE_URL' => value)
  end
end

def successful_body(app, options = {})
  retry_limit = options[:retry_limit] || 50
  Excon.get("http://#{app.name}.herokuapp.com", :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end

def create_file_with_size_in(size, dir)
  name = File.join(dir, SecureRandom.hex(16))
  File.open(name, 'w') {|f| f.print([ 1 ].pack("C") * size) }
  Pathname.new name
end
