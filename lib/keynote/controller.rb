# frozen_string_literal: true

module Keynote
  # `Keynote::Controller` is mixed into `ActionController::Base` and
  # `ActionMailer::Base`, providing a `present` method (aliased to `k`) for
  # instantiating presenters.
  module Controller
    # Instantiate a presenter.
    # @see Keynote.present
    def present(...) = Keynote.present(view_context, ...)

    alias_method :k, :present
  end
end
