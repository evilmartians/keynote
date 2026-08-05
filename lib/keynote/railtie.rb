# frozen_string_literal: true

require "rails/railtie"

module Keynote
  # @private
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      load_test_integration
    end

    ActiveSupport.on_load(:action_view) do
      include Keynote::Helper
    end

    ActiveSupport.on_load(:action_controller) do
      include Keynote::Controller
    end

    ActiveSupport.on_load(:action_mailer) do
      include Keynote::Controller
    end

    def self.load_test_integration
      if defined?(RSpec::Rails)
        require "keynote/testing/rspec"
      end

      if defined?(ActiveSupport::TestCase)
        require "keynote/testing/minitest"
      end
    end
  end
end
