require "rspec/core"
require "rspec/retry"
require "hatchet"
require "java-properties"

DEFAULT_OPENJDK_VERSION="1.8"

RSpec.configure do |config|
  config.fail_if_no_examples = true
  config.full_backtrace      = true
  # rspec-retry
  config.verbose_retry       = true
  config.default_retry_count = 2 if ENV["CI"]
end

def new_default_hatchet_runner(*args, **kwargs)
  kwargs[:stack] ||= ENV["DEFAULT_APP_STACK"]
  kwargs[:config] ||= {}

  ENV.keys.each do |key|
    if key.start_with?("DEFAULT_APP_CONFIG_")
      kwargs[:config][key.delete_prefix("DEFAULT_APP_CONFIG_")] ||= ENV[key]
    end
  end

  Hatchet::Runner.new(*args, **kwargs)
end

def set_java_version(version_string)
  set_system_properties_key("java.runtime.version", version_string)
end

def set_maven_version(version_string)
  set_system_properties_key("maven.version", version_string)
end

def set_system_properties_key(key, value)
  properties = {}

  if File.file?("system.properties")
    properties = JavaProperties.load("system.properties")
  end

  properties[key.to_sym] = value
  JavaProperties.write(properties, "system.properties")
end

def write_to_procfile(content)
  File.open("Procfile", "w") do |file|
    file.write(content)
  end
end

def run(cmd)
  out = `#{cmd}`
  raise "Command #{cmd} failed with output #{out}" unless $?.success?
  out
end

def http_get(app, options = {})
  retry_limit = options[:retry_limit] || 50
  path = options[:path] ? "/#{options[:path]}" : ""
  Excon.get("https://#{app.name}.herokuapp.com#{path}", :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end
