# frozen_string_literal: true

module Keynote
  # `Keynote::Helper` is mixed into `ActionView::Base`, providing a `present`
  # method (aliased to `k`) for instantiating presenters.
  module Helper
    # Instantiate a presenter.
    # @see Keynote.present
    def present(...) = Keynote.present(self, ...)

    alias_method :k, :present
  end
end
