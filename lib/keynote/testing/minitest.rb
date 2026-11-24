# frozen_string_literal: true

require "keynote/testing/test_present_method"

module Keynote
  module TestHelper
    include TestPresentMethod

    def view
      if defined?(@controller) && @controller
        @controller.view_context
      else
        ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
      end
    end

    alias_method :view_context, :view
  end
end
