# frozen_string_literal: true

# Keynote is a library for defining and instantiating presenters,
# objects that encapsulate view logic.
#
# @see file:README.md
module Keynote
  class << self
    # Create or retrieve a presenter wrapping zero or more objects.
    # If a block is given, yield the presenter into it.
    #
    # The first parameter is a Rails view context, but you'll usually access
    # this method through `Keynote::Helper#present`,
    # `Keynote::Controller#present`, or `Keynote::Presenter#present`, all of
    # which handle the view context parameter automatically.
    #
    # @see Keynote::Helper#present
    # @see Keynote::Controller#present
    # @see Keynote::Presenter#present
    #
    # @overload present(view, *objects)
    #   Return a presenter wrapping the given objects. The type of the
    #   presenter will be inferred from the type of the first object.
    #   @example
    #     present(view, MyModel.new)           # => #<MyModelPresenter:0x0001>
    #   @param [ActionView::Base] view
    #   @param [Array] objects
    #   @return [Keynote::Presenter]
    #
    # @overload present(view, presenter_name, *objects)
    #   Return a presenter wrapping the given objects. The type of the
    #   presenter is specified in underscore form by the first parameter.
    #   @example
    #     present(view, :foo_bar, MyModel.new) # => #<FooBarPresenter:0x0002>
    #   @param [ActionView::Base] view
    #   @param [Symbol, String] presenter_name
    #   @param [Array] objects
    #   @return [Keynote::Presenter]
    #
    def present(view, *objects)
      name = if objects[0].is_a?(Symbol) || objects[0].is_a?(String)
        objects.shift
      else
        presenter_name_from_object(objects[0])
      end

      Cache.fetch(name, view, *objects) do
        presenter_from_name(name).new(view, *objects).tap do |presenter|
          yield presenter if block_given?
        end
      end
    end

    private

    def presenter_name_from_object(object)
      object.class.to_s.underscore
    end

    def presenter_from_name(name)
      "#{name.to_s.camelize}Presenter".constantize
    end
  end
end
