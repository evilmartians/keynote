# frozen_string_literal: false

module Keynote
  # HTML markup in Ruby.
  #
  # To invoke Rumble, call the `build_html` method in a presenter.
  #
  # ## 1. Syntax
  #
  # There are four basic forms:
  #
  # ```ruby
  # tagname(content)
  #
  # tagname(content, attributes)
  #
  # tagname do
  #   content
  # end
  #
  # tagname(attributes) do
  #   content
  # end
  # ```
  #
  # Example:
  #
  # ``` ruby
  # build_html do
  #   div :id => :content do
  #     h1 'Hello World', :class => :main
  #   end
  # end
  # ```
  #
  # ``` html
  # <div id="content">
  #   <h1 class="main">Hello World</h1>
  # </div>
  # ```
  #
  # ## 2. Element classes and IDs
  #
  # You can easily add classes and IDs by hooking methods onto the container:
  #
  # ``` ruby
  # div.content! do
  #   h1.main 'Hello World'
  # end
  # ```
  #
  # You can mix and match as you'd like (`div.klass.klass1.id!`), but you can
  # only provide content and attributes on the *last* call:
  #
  # ``` ruby
  # # This is not valid:
  # form(:action => :post).world do
  #   input
  # end
  #
  # # But this is:
  # form.world(:action => :post) do
  #   input
  # end
  # ```
  #
  # ## 3. Text
  #
  # Sometimes you need to insert plain text:
  #
  # ```ruby
  # p.author do
  #   text 'Written by '
  #   a 'Bluebie', :href => 'http://creativepony.com/'
  #   br
  #   text link_to 'Home', '/'
  # end
  # ```
  #
  # ``` html
  # <p class="author">
  #   Written by
  #   <a href="http://creativepony.com/">Bluebie</a>
  #   <br>
  #   <a href="/">Home</a>
  # </p>
  # ```
  #
  # You can also insert literal text by returning it from a block (or passing
  # it as a parameter to the non-block form of a tag method):
  #
  # ``` ruby
  # p.author do
  #   link_to 'Home', '/'
  # end
  # ```
  #
  # ``` html
  # <p class="author">
  #   <a href="/">Home</a>
  # </p>
  # ```
  #
  # Be aware that Rumble ignores the string in a block if there's other tags
  # there:
  #
  # ``` ruby
  # div.comment do
  #   div.author "BitPuffin"
  #   "<p>Silence!</p>"
  # end
  # ```
  #
  # ``` html
  # <div class="comment">
  #   <div class="author">BitPuffin</div>
  # </div>
  # ```
  #
  # ## 4. Escaping
  #
  # The version of Rumble that's embedded in Keynote follows normal Rails
  # escaping rules. When text enters Rumble (by returning it from a block,
  # passing it as a parameter to a tag method, or using the `text` method),
  # it's escaped if and only if `html_safe?` returns false. That means that
  # Rails helpers generally don't need special treatment, but strings need to
  # have `html_safe` called on them to avoid escaping.
  #
  # ## 5. In practice
  #
  # ``` ruby
  # class ArticlePresenter < Keynote::Presenter
  #   presents :article
  #
  #   def published_at
  #     build_html do
  #       div.published_at do
  #         span.date publication_date
  #         span.time publication_time
  #       end
  #     end
  #   end
  #
  #   def publication_date
  #     article.published_at.strftime("%A, %B %e").squeeze(" ")
  #   end
  #
  #   def publication_time
  #     article.published_at.strftime("%l:%M%p").delete(" ")
  #   end
  # end
  # ```
  #
  # @author Rumble is (c) 2011 Magnus Holm (https://github.com/judofyr).
  # @author Documentation mostly borrowed from Mab, (c) 2012 Magnus Holm.
  # @see https://github.com/judofyr/rumble
  # @see https://github.com/camping/mab
  module Rumble
    # A class for exceptions raised by Rumble.
    class Error < StandardError
    end

    # A basic set of commonly-used HTML tags. These are included as methods
    # on all presenters by default.
    BASIC = %w[a b br button del div em form h1 h2 h3 h4 h5 h6 hr i img input
      label li link ol optgroup option p pre script select span strong sub sup
      table tbody td textarea tfoot th thead time tr ul]

    # A more complete set of HTML5 tags. You can use these by calling
    # `use_html_5_tags` in a presenter's class body.
    COMPLETE = %w[abbr acronym address applet area article aside audio base
      basefont bdo big blockquote body canvas caption center cite code col
      colgroup command datalist dd details dfn dir dl dt embed fieldset
      figcaption figure font footer frame frameset head header hgroup iframe
      ins keygen kbd legend map mark menu meta meter nav noframes noscript
      object output param progress q rp rt ruby s samp section small source
      strike style summary title tt u var video wbr xmp]

    # @private
    SELFCLOSING = %w[base meta link hr br param img area input col frame]

    # @private
    def self.included(base)
      define_tags(base, BASIC)
    end

    # @private
    def self.define_tags(base, tags)
      tags.each do |tag|
        sc = SELFCLOSING.include?(tag).inspect

        base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{tag}(*args, &blk)                   # def a(*args, &blk)
            rumble_tag :#{tag}, #{sc}, *args, &blk  #   rumble_tag :a, false, *args, &blk
          end                                       # end
        RUBY
      end
    end

    # @private
    def self.use_html_5_tags(base)
      define_tags(base, COMPLETE)
    end

    # We need our own copy of this, the normal Rails html_escape helper, so
    # that we can access it from inside Tag objects.
    # @private
    def self.html_escape(s)
      s = s.to_s
      if s.html_safe?
        s
      else
        s.gsub(/[&"'><]/, ERB::Util::HTML_ESCAPE).html_safe
      end
    end

    # @private
    class Context < Array
      def to_s
        join.html_safe
      end
    end

    # @private
    class Tag
      def initialize(context, instance, name, sc)
        @context = context
        @instance = instance
        @name = name
        @sc = sc
        @done, @content = nil
      end

      def attributes
        @attributes ||= {}
      end

      def merge_attributes(attrs)
        if defined?(@attributes)
          @attributes.merge!(attrs)
        else
          @attributes = attrs
        end
      end

      def respond_to_missing?(name, include_private = false)
        true
      end

      def method_missing(name, content = nil, attrs = nil, &blk)
        name = name.to_s

        if name[-1] == "!"
          attributes[:id] = name[0..-2]
        elsif attributes.has_key?(:class)
          attributes[:class] += " #{name}"
        else
          attributes[:class] = name
        end

        insert(content, attrs, &blk)
      end

      def insert(content = nil, attrs = nil, &blk)
        raise Error, "This tag is already closed" if @done

        if content.is_a?(Hash)
          attrs = content
          content = nil
        end

        attrs = flatten_attr_hash(attrs, :aria)
        attrs = flatten_attr_hash(attrs, :data)
        merge_attributes(attrs) if attrs

        if block_given?
          raise Error, "`#{@name}` is not allowed to have content" if @sc
          @done = :block
          before = @context.size
          res = yield
          @content = Rumble.html_escape(res) if @context.size == before
          @context << "</#{@name}>"
        elsif content
          raise Error, "`#{@name}` is not allowed to have content" if @sc
          @done = true
          @content = Rumble.html_escape(content)
        elsif attrs
          @done = true
        end

        self
      rescue
        @instance.rumble_cleanup
        raise $!
      end

      def to_ary
        nil
      end

      def to_str
        to_s
      end

      def html_safe?
        true
      end

      def to_s
        if @instance.rumble_context.eql?(@context)
          @instance.rumble_cleanup
          @context.to_s
        else
          @result ||= begin
            res = "<#{@name}#{attrs_to_s}>"
            res << @content if @content
            res << "</#{@name}>" if !@sc && @done != :block
            res.html_safe
          end
        end
      end

      def inspect
        to_s.inspect
      end

      private

      # If the given attrs contain an `aria` or `data` hash, flatten its
      # contents into hyphenated attribute names.
      def flatten_attr_hash(attrs, name)
        if attrs && attrs[name].is_a?(Hash)
          attrs = attrs.dup
          attrs.delete(name).each do |key, value|
            next if value.nil?
            attrs[:"#{name}-#{key}"] = value.to_s
          end
        end

        attrs
      end

      def attrs_to_s
        attributes.inject("") do |res, (name, value)|
          next res unless value

          value =
            if value.is_a?(Array)
              value.map { |val| Rumble.html_escape(val) }.join(" ")
            elsif value == true
              name.to_s
            else
              Rumble.html_escape(value)
            end

          res << " #{name}=\"#{value.gsub('"', "&quot;")}\""
          res
        end
      end
    end

    # Generate HTML using Rumble tag methods. If tag methods are called
    # outside a `build_html` block, they'll raise an exception.
    def build_html
      if defined?(@rumble_context)
        ctx = @rumble_context
      end
      @rumble_context = Context.new
      yield
      rumble_cleanup(ctx).to_s
    end

    # Generate a text node. This is helpful in situations where an element
    # contains both text and markup.
    def text(str = nil, &blk)
      str = Rumble.html_escape(str || blk.call)

      if defined?(@rumble_context) && @rumble_context
        @rumble_context << str
      else
        str
      end
    end

    # @private
    def rumble_context
      defined?(@rumble_context) ? @rumble_context : nil
    end

    # @private
    def rumble_cleanup(value = nil)
      defined?(@rumble_context) ? @rumble_context : nil
    ensure
      @rumble_context = value
    end

    private

    def rumble_tag(name, sc, content = nil, attrs = nil, &blk)
      if !defined?(@rumble_context) || !@rumble_context
        raise Rumble::Error, "Must enclose tags in `rumble { ... }` block"
      end

      context = @rumble_context
      tag = Tag.new(context, self, name, sc)
      context << tag
      tag.insert(content, attrs, &blk)
    end
  end
end
