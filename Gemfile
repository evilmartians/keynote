# frozen_string_literal: true

source "https://rubygems.org"

gem "debug", platform: :mri

gemspec

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

gem "benchmark-ips", require: false
gem "lefthook", require: false

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem "rails", "~> 7.0"
end
