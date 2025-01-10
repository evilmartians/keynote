# frozen_string_literal: true

require "rspec/core"
require "keynote/testing/test_present_method"

module Keynote
  module ExampleGroup
    def self.included(base)
      base.send :include, RSpec::Rails::ViewExampleGroup
      base.send :include, TestPresentMethod
      base.metadata[:type] = :presenter
    end
  end
end

RSpec.configure do |config|
  if RSpec::Core::Version::STRING.starts_with?("3")
    config.include Keynote::ExampleGroup,
      type: :presenter,
      file_path: %r{spec.presenters}
  else
    config.include Keynote::ExampleGroup,
      type: :presenter,
      example_group: {file_path: %r{spec.presenters}}
  end
end
