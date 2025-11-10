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

def find_output_start_index(lines)
  # Find the first "app detected" line. This skips the buildpack list at the beginning which will contain a GitHub URL
  # for the buildpack under test that will be different for each PR/branch under test.
  lines.index { |line| line.match?(/-----> .* app detected/) }
end

def find_output_end_index(lines)
  # Find the end of relevant build output. For successful builds, this is the "Done: 12.3M" line after compression.
  # For failed builds, this is the "Push failed" line. This skips build-system output after these lines that is
  # irrelevant for our tests and changes for each deploy.
  success_end_index = lines.index { |line| line.match?(/Done: \d+(\.\d+)?[MG]/) }
  failure_end_index = lines.index { |line| line.match?(/!\s+Push failed/) }
  [success_end_index, failure_end_index].compact.first
end

def clean_output(output)
  # Remove output from the build system before and after the actual build
  lines = output.lines
  output = lines[find_output_start_index(lines)..find_output_end_index(lines)].join

  generic = {
    ##################################################
    # Generic
    ##################################################
    # Trailing whitespace characters added by Git:
    # https://github.com/heroku/hatchet/issues/162
    / {8}(?=\R)/ => '',
    # ANSI colour codes used in buildpack output (e.g. error messages).
    /\e\[[0-9;]+m/ => '',
    # Trailing spaces from empty "remote: " lines added by Heroku
    /^remote: $/ => '',
    /remote:        Released v\d+/ => 'remote:        Released $VERSION',
    # Build directory
    %r{/tmp/build_[0-9a-f]{8}} => '$BUILD_DIR',
    # Build id
    /build_[0-9a-f]{8}/ => '$BUILD_ID',

    ##################################################
    # Java
    ##################################################
    /(OpenJDK|Java) \d+\.\d+\.\d+(_\d+)?/ => '\1 $VERSION',

    ##################################################
    # sbt
    ##################################################
    # Trailing space from empty sbt log lines (e.g. "remote:        [info] ")
    /\[(info|warn|error|success|debug)\] $/ => '[\1]',
    # Datetime strings from sbt (e.g. May 31, 1985 11:38:00 AM or May 31, 1985, 11:38:00 AM)
    /([A-Z][a-z]{2}) (\d{1,2}), (\d{4}),? (\d{1,2}):(\d{2}):(\d{2}) ([AP]M)/ => '$DATETIME',
    # Various timing output from sbt
    /\d+ms/ => '$DURATION',
    /Total time: .*?,/ => 'Total time: $DURATION,',
    /Compilation completed in (.*?)$/ => 'Compilation completed in $DURATION.', # sbt 0.x
    /Compilation completed in (.*?)\.$/ => 'Compilation completed in $DURATION.', # sbt 1.x
  }

  output = generic.reduce(output) { |output, (pattern, replacement)| output.gsub(pattern, replacement) }

  # Save the cleaned output to disk so it can be copied byte-for-byte when writing or updating test expectations.
  # Copying from terminal output can introduce issues (especially with whitespace output). Writing this file every time
  # is inexpensive and ensures it's always available when needed.
  File.write('/tmp/scala_buildpack_integration_last_test_output.txt', output)

  output
end
