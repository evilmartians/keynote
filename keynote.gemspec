# frozen_string_literal: true

require_relative "lib/keynote/version"

Gem::Specification.new do |s|
  s.name = "keynote"
  s.version = Keynote::VERSION
  s.authors = ["Ryan Fitzgerald", "Vladimir Dementyev"]
  s.email = ["rwfitzge@gmail.com", "dementiev.vm@gmail.com"]
  s.summary = "Flexible presenters for Rails"
  s.description = '
    A presenter is an object that encapsulates view logic. Like Rails helpers,
    presenters help you keep complex logic out of your templates. Keynote
    provides a consistent interface for defining and instantiating presenters.
  '.gsub(/\s+/, " ")
  s.homepage = "https://github.com/evilmartians/keynote"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/evilmartians/keynote/issues",
    "changelog_uri" => "https://github.com/evilmartians/keynote/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/keynote",
    "homepage_uri" => "https://github.com/evilmartians/keynote",
    "source_code_uri" => "https://github.com/evilmartians/keynote"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + Dir.glob("lib/.rbnext/**/*") + Dir.glob("bin/**/*") + %w[README.md LICENSE.txt CHANGELOG.md .yardopts]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.0"

  s.add_dependency "actionview", ">= 7.0.0"

  s.add_development_dependency "ammeter", "~> 1.1"
  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.9"
  s.add_development_dependency "minitest", "~> 5.0"

  s.add_development_dependency "combustion", ">= 1.1"
  s.add_development_dependency "slim"
  s.add_development_dependency "haml"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "yard"
  s.add_development_dependency "webrick"

  if ENV["RELEASING_GEM"].nil? && File.directory?(File.join(__dir__, ".git"))
    s.add_runtime_dependency "ruby-next", "~> 1.0"
  else
    s.add_dependency "ruby-next-core", "~> 1.0"
  end
end
