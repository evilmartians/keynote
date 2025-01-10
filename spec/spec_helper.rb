# frozen_string_literal: true

begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

require "ruby-next/language/runtime"

if ENV["CI"] == "true"
  # Only transpile specs, source code MUST be loaded from pre-transpiled files
  RubyNext::Language.include_patterns.clear
  RubyNext::Language.include_patterns << "#{__dir__}/*.rb"
end

ENV["RAILS_ENV"] = "test"

require "combustion"
require "keynote"

require "fileutils"
require "slim"
require "haml"
require "haml/template"

begin
  # See https://github.com/pat/combustion
  Combustion.initialize! do
    config.logger = Logger.new(nil)
    config.log_level = :fatal
  end
rescue => e
  # Fail fast if application couldn't be loaded
  $stdout.puts "Failed to load the app: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
  exit(1)
end

require "action_controller/railtie"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed
end
