# frozen_string_literal: false

require "action_view"

module Keynote
  # The `Inline` mixin lets you write inline templates as comments inside the
  # body of a presenter method. You can use any template language supported by
  # Rails.
  #
  # ## Basic usage
  #
  # After extending the `Keynote::Inline` module in your presenter class, you
  # can generate HTML by calling the `erb` method and immediately following it
  # with a block of comments containing your template:
  #
  #     def link
  #       erb
  #       # <%= link_to user_url(current_user) do %>
  #       #   <%= image_tag("image1.jpg") %>
  #       #   <%= image_tag("image2.jpg") %>
  #       # <% end %>
  #     end
  #
  # Calling this method renders the ERB template, including passing the calls
  # to `link_to`, `user_url`, `current_user`, and `image_tag` back to the
  # presenter object (and then to the view).
  #
  # ## Passing variables
  #
  # There are a couple of different ways to pass local variables into an inline
  # template. The easiest is to pass the `binding` object into the template
  # method, giving access to all local variables:
  #
  #     def local_binding
  #       x = 1
  #       y = 2
  #
  #       erb binding
  #       # <%= x + y %>
  #     end
  #
  # You can also pass a hash of variable names and values instead:
  #
  #     def local_binding
  #       erb x: 1, y: 2
  #       # <%= x + y %>
  #     end
  #
  # ## The `inline` method
  #
  # If you want to use template languages other than ERB, you have to define
  # methods for them by calling the {Keynote::Inline#inline} method on a
  # presenter class:
  #
  #     class MyPresenter < Keynote::Presenter
  #       extend Keynote::Inline
  #       presents :user, :account
  #       inline :haml
  #     end
  #
  # This defines a `#haml` instance method on the `MyPresenter` class.
  #
  # If you want to make inline templates available to all of your presenters,
  # you can add an initializer like this to your application:
  #
  #     class Keynote::Presenter
  #       extend Keynote::Inline
  #       inline :haml, :slim
  #     end
  #
  # This will add `#erb`, `#haml`, and `#slim` instance methods to all of your
  # presenters.
  module Inline
    # For each template format given as a parameter, add an instance method
    # that can be called to render an inline template in that format. Any
    # file extension supported by Rails is a valid parameter.
    # @example
    #   class UserPresenter < Keynote::Presenter
    #     presents :user
    #     inline :haml
    #
    #     def header
    #       full_name = "#{user.first_name} #{user.last_name}"
    #
    #       haml binding
    #       # div#header
    #       #   h1= full_name
    #       #   h3= user.most_recent_status
    #     end
    #   end
    def inline(*formats)
      require "action_view/context"

      Array(formats).each do |format|
        define_method format do |locals = {}|
          Renderer.new(self, locals, caller(1)[0], format).render
        end
      end
    end

    # Extending `Keynote::Inline` automatically creates an `erb` method on the
    # base class.
    def self.extended(base)
      base.inline :erb
      base.include InstanceMethods
    end

    module InstanceMethods
      # A callback for Action View: https://github.com/rails/rails/blob/a32eab53a58540b9ca57da429c5f64564db43126/actionview/lib/action_view/base.rb#L261
      def _run(method, template, locals, buffer, add_to_stack: true, has_strict_locals: false, &block)
        old_output_buffer, old_virtual_path, old_template = @output_buffer, @virtual_path, @current_template
        @current_template = template if add_to_stack
        @output_buffer = buffer
        public_send(method, locals, buffer, &block)
      ensure
        @output_buffer, @virtual_path, @current_template = old_output_buffer, old_virtual_path, old_template
      end
    end

    # @private
    class Renderer
      def initialize(presenter, locals, caller_line, format)
        @presenter = presenter
        @locals = extract_locals(locals)
        @template = Cache.fetch(*parse_caller(caller_line), format, @locals)
      end

      def render
        @template.render(@presenter, @locals)
      end

      private

      def extract_locals(locals)
        return locals unless locals.is_a?(Binding)

        locals.eval("local_variables").map do |local|
          [local, locals.eval(local.to_s)]
        end.to_h
      end

      def parse_caller(caller_line)
        file, rest = caller_line.split ":", 2
        line, _ = rest.split " ", 2

        [file.strip, line.to_i]
      end
    end

    # @private
    class Cache
      COMMENTED_LINE = /^\s*#(.*)$/

      def self.fetch(source_file, line, format, locals)
        instance = (Thread.current[:_keynote_template_cache] ||= Cache.new)
        instance.fetch(source_file, line, format, locals)
      end

      def self.reset
        Thread.current[:_keynote_template_cache] = nil
      end

      def initialize
        @cache = {}
      end

      def fetch(source_file, line, format, locals)
        local_names = locals.keys.sort
        cache_key = ["#{source_file}:#{line}", *local_names].freeze
        new_mtime = File.mtime(source_file).to_f

        template, mtime = @cache[cache_key]

        if new_mtime != mtime
          source = read_template(source_file, line)

          template = Template.new(source, cache_key[0],
            handler_for_format(format), format:, locals: local_names)

          @cache[cache_key] = [template, new_mtime]
        end

        template
      end

      private

      def read_template(source_file, line_num)
        result = ""

        File.foreach(source_file).drop(line_num).each do |line|
          if line =~ COMMENTED_LINE
            result << $1 << "\n"
          else
            break
          end
        end

        unindent result.chomp
      end

      def handler_for_format(format)
        ActionView::Template.handler_for_extension(format.to_s)
      end

      # Borrowed from Pry, which borrowed it from Python.
      def unindent(text, left_padding = 0)
        margin = text.scan(/^[ \t]*(?=[^ \t\n])/).inject do |current_margin, next_indent|
          if next_indent.start_with?(current_margin)
            current_margin
          elsif current_margin.start_with?(next_indent)
            next_indent
          else
            ""
          end
        end

        text.gsub(/^#{margin}/, " " * left_padding)
      end
    end

    # @private
    class Template < ActionView::Template
      # The only difference between this #compile! and the normal one is that
      # we call `view.class` instead of `view.singleton_class`, so that the
      # template method gets defined as an instance method on the presenter
      # and therefore sticks around between presenter instances.
      def compile!(view)
        return if @compiled

        @compile_mutex.synchronize do
          return if @compiled

          compile(view.class)

          @source = nil if defined?(@virtual_path) && @virtual_path
          @compiled = true
        end
      end
    end
  end
end
