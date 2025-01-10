# frozen_string_literal: true

module Keynote
  # `Keynote::Cache` memoizes presenter instances, reducing the overhead of
  # calling `Keynote.present` repeatedly with the same parameters.
  module Cache
  end

  class << Cache
    # Return a cached presenter for the given parameters, or yield and cache
    # the block's return value for next time.
    #
    # The cached presenters are stored in an instance variable on the current
    # view context, so they'll be garbage-collected when the view context goes
    # out of scope.
    #
    # @param [Symbol] name
    # @param [ActionView::Base] view
    # @param [Array] objects
    # @return [Keynote::Presenter]
    def fetch(name, view, *objects)
      # If we don't have a view, just bail out and return a fresh presenter
      # every time.
      if view.nil?
        return yield
      end

      # Initialize our cache on the view context if it doesn't already exist.
      if view.instance_variable_defined?(:@_keynote_cache)
        cache = view.instance_variable_get(:@_keynote_cache)
      else
        cache = {}
        view.instance_variable_set(:@_keynote_cache, cache)
      end

      # Key each entry by the name of the presenter and the object_id of each
      # of the objects involved.
      key = [name, *objects.map(&:object_id)]

      # If we have a cached presenter, return it; if not, yield, store the
      # result, and return that.
      cache[key] or (cache[key] = yield)
    end
  end
end
