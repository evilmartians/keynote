# frozen_string_literal: true

# Mutually exclusive with the Keynote::TestCase defined in
# keynote/testing/test_unit. This is kind of icky but consistent with how
# MT::R itself replaces the Rails test case classes.

require "keynote/testing/test_present_method"

module Keynote
  class TestCase < ::ActionView::TestCase
    include TestPresentMethod

    # describe SomePresenter do
    register_spec_type(self) do |desc|
      desc < Keynote::Presenter if desc.is_a?(Class)
    end

    # describe "SomePresenter" do
    register_spec_type(/presenter( ?test)?\z/i, self)

    # Don't try to include any particular helper, since we're not testing one
    def self.include_helper_modules!
      include _helpers
    end
  end
end
