# frozen_string_literal: true

require 'English'
require 'rspec/core'
require 'rspec/retry'
require 'hatchet'
require 'java-properties'

DEFAULT_OPENJDK_VERSION = '1.8'

RSpec.configure do |config|
  config.fail_if_no_examples = true
  config.full_backtrace      = true
  # rspec-retry
  config.verbose_retry       = true
  config.default_retry_count = 2 if ENV['CI']
end

def new_default_hatchet_runner(*args, **kwargs)
  kwargs[:stack] ||= ENV.fetch('DEFAULT_APP_STACK', nil)
  kwargs[:config] ||= {}

  ENV.each_key do |key|
    if key.start_with?('DEFAULT_APP_CONFIG_')
      kwargs[:config][key.delete_prefix('DEFAULT_APP_CONFIG_')] ||= ENV.fetch(key,
                                                                              nil)
    end
  end

  Hatchet::Runner.new(*args, **kwargs)
end

def write_to_procfile(content)
  File.write('Procfile', content)
end

def run(cmd)
  out = `#{cmd}`
  raise "Command #{cmd} failed with output #{out}" unless $CHILD_STATUS.success?

  out
end

def http_get(app, options = {})
  retry_limit = options[:retry_limit] || 50
  path = options[:path] ? "/#{options[:path]}" : ''
  Excon.get("#{app.platform_api.app.info(app.name).fetch('web_url')}#{path}", idempotent: true, expects: 200,
                                                                              retry_limit: retry_limit).body
end
