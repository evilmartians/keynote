# frozen_string_literal: true

module Keynote
  # Keynote::Presenter is a base class for presenters, objects that encapsulate
  # view logic.
  #
  # @see file:README.md
  class Presenter
    include Keynote::Rumble

    class << self
      attr_writer :object_names

      # Define the names and number of the objects presented by this class.
      # This replaces the default one-parameter constructor with one that takes
      # an extra parameter for each presented object.
      #
      # @param [Array<Symbol>] objects One symbol for each of the models that
      #   will be required to instantiate this presenter. Each symbol will be
      #   used as the accessor and instance variable name for its associated
      #   parameter, but an object of any class can be given for any parameter.
      #
      # @example
      #   class PostPresenter
      #     presents :blog_post, :author
      #   end
      #
      #   # In a view
      #   presenter = k(:post, @some_post, @some_user)
      #   presenter.blog_post # == @some_post
      #   presenter.author    # == @some_user
      #
      def presents(*objects)
        self.object_names = objects.dup

        objects.unshift :view
        attr_reader(*objects)

        param_list = objects.join(", ")
        ivar_list = objects.map { "@#{it}" }.join(", ")

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def initialize(#{param_list})  # def initialize(view, foo)
            #{ivar_list} = #{param_list} #   @view, @foo = view, foo
          end                            # end
        RUBY
      end

      # Define a more complete set of HTML5 tag methods. The extra tags are
      # listed in {Keynote::Rumble::COMPLETE}.
      def use_html_5_tags = Rumble.use_html_5_tags(self)

      # List the object names this presenter wraps. The default is an empty
      # array; calling `presents :foo, :bar` in the presenter's class body will
      # cause `object_names` to return `[:foo, :bar]`.
      # @return [Array<Symbol>]
      def object_names
        @object_names ||= []
      end
    end

    # @private (used by Keynote::Cache to keep the view context up-to-date)
    attr_writer :view

    # Create a presenter. The default constructor takes one parameter, but
    # calling `presents` replaces it with a generated constructor.
    # @param [ActionView::Base] view_context
    # @see Keynote::Presenter.presents
    def initialize(view_context)
      @view = view_context
    end

    # Instantiate another presenter.
    # @see Keynote.present
    def present(...)
      Keynote.present(@view, ...)
    end
    alias_method :k, :present

    # @private
    def inspect
      objects = self.class.object_names
      render = proc { |name| "#{name}: #{send(name).inspect}" }

      if objects.any?
        "#<#{self.class} #{objects.map(&render).join(", ")}>"
      else
        "#<#{self.class}>"
      end
    end

    # @private
    def respond_to_missing?(method_name, include_private = true)
      @view.respond_to?(method_name, true)
    end

    # Presenters proxy unknown method calls to the view context, allowing you
    # to call `h`, `link_to`, and anything else defined in a helper module.
    #
    # @example
    #   def title_link
    #     link_to blog_post_url(blog_post) do
    #       "#{h author.name} &mdash; #{h blog_post.title}".html_safe
    #     end
    #   end
    def method_missing(method_name, ...)
      if @view.respond_to?(method_name, true)
        @view.send(method_name, ...)
      else
        super
      end
    end

    # @private
    # We have to make a logger method available so that ActionView::Template
    # can safely treat a presenter as a view object.
    def logger = Rails.logger

    private

    # We have to explicitly proxy `#capture` because ActiveSupport creates a
    # `Kernel#capture` method.
    def capture(...) = @view.capture(...)
  end
end
