# frozen_string_literal: true

# Based on the original Rumble tests (c) 2011 Magnus Holm (https://github.com/judofyr).

require "test_helper"

class TestRumble < Minitest::Test
  class Context
    include Keynote::Rumble
  end

  def ctx = @ctx ||= Context.new
  delegate_missing_to :ctx
  # Make sure Rumble's #p is used, not Kernel's
  undef_method :p

  def assert_rumble(str, &blk)
    exp = str.gsub(/(\s+(<)|>\s+)/) { $2 || ">" }
    res = nil
    build_html {
      res = yield.to_s
    }
    assert_equal exp, res
    assert_instance_of ActiveSupport::SafeBuffer, res
  end

  def setup
    @rumble_context = nil
    super
    assert_nil @rumble_context
  end

  def teardown
    super
    assert_nil @rumble_context
  end

  def test_simple
    str = <<-HTML
      <form>
        <div id="wrapper">
          <h1>My Site</h1>
        </div>
        <div class="input">
          <input type="text" name="value">
        </div>
      </form>
    HTML

    assert_rumble str do
      form do
        div.wrapper! do
          h1 "My Site"
        end

        div.input do
          input type: "text", name: "value"
        end
      end
    end
  end

  def test_string_data
    assert_rumble '<div data="whatever"></div>' do
      div data: "whatever"
    end
  end

  def test_true_as_value
    assert_rumble '<input disabled="disabled">' do
      input disabled: true
    end
  end

  def test_hash_data
    str = <<-HTML
      <div data-modal="true" data-safe="&quot;&quot;&quot;" data-unsafe="&quot;&amp;quot;&quot;">
      </div>
    HTML

    assert_rumble str do
      div data: {
        modal: true,
        safe: '"&quot;"'.html_safe,
        absent: nil,
        unsafe: '"&quot;"'
      }
    end
  end

  def test_string_aria
    assert_rumble '<div aria="whatever"></div>' do
      div aria: "whatever"
    end
  end

  def test_hash_aria
    str = <<-HTML
      <div aria-modal="true" aria-safe="&quot;&quot;&quot;" aria-unsafe="&quot;&amp;quot;&quot;">
      </div>
    HTML

    assert_rumble str do
      div aria: {
        modal: true,
        safe: '"&quot;"'.html_safe,
        absent: nil,
        unsafe: '"&quot;"'
      }
    end
  end

  def test_array_attrs
    str = <<-HTML
      <div class="hello &quot;uns&amp;amp;fe&quot; &quot;w&amp;rld&quot;">
      </div>
    HTML

    assert_rumble str do
      div class: ["hello", '"uns&amp;fe"', '"w&amp;rld"'.html_safe]
    end
  end

  def test_nil_attr
    str = <<-HTML
      <div id="id" class="class"></div>
    HTML

    assert_rumble str do
      div id: "id", title: nil, class: "class"
    end
  end

  def test_several
    str = <<-HTML
      <p>Hello</p>
      <p>World</p>
    HTML

    assert_rumble str do
      p "Hello"
      p "World"
    end
  end

  def test_several_capture
    str = <<-HTML
      <div>
        <p>Hello</p>
        <p>Hello</p>
        |
        <p>World</p>
        <p>World</p>
      </div>
    HTML

    assert_rumble str do
      div do
        (%w[Hello World].map { |x|
          build_html {
            p x
            p x
          }
        } * "|").html_safe
      end
    end
  end

  def test_capture_raise
    assert_raises RuntimeError do
      build_html {
        div do
          build_html { raise }
        end
      }
    end
  end

  def test_escape
    str = <<-HTML
      <p class="&quot;test&quot;">Hello &amp; World</p>
    HTML

    assert_rumble str do
      p "Hello & World", class: '"test"'
    end
  end

  def test_multiple_css_classes
    str = <<-HTML
      <p class="one two three"></p>
    HTML

    assert_rumble str do
      p.one.two.three
    end
  end

  def test_selfclosing
    assert_rumble "<br>" do
      br
    end
  end

  def test_text
    assert_rumble "hello" do
      text "hello"
    end
  end

  def test_escaping_unsafe_input
    str = "<br>"

    assert_rumble "<div>&lt;br&gt;</div>" do
      div { str }
    end

    assert_rumble "<div>&lt;br&gt;</div>" do
      div str
    end

    assert_rumble "<div>&lt;br&gt;</div>" do
      div { text { str } }
    end

    assert_rumble "<div>&lt;br&gt;</div>" do
      div { text str }
    end
  end

  def test_not_escaping_safe_input
    str = "<br>".html_safe

    assert_rumble "<div><br></div>" do
      div { str }
    end

    assert_rumble "<div><br></div>" do
      div str
    end

    assert_rumble "<div><br></div>" do
      div { text { str } }
    end

    assert_rumble "<div><br></div>" do
      div { text str }
    end
  end

  def test_error_tags_outside_rumble_context
    assert_raises Keynote::Rumble::Error do
      div "content"
    end
  end

  def test_error_selfclosing_content
    assert_raises Keynote::Rumble::Error do
      build_html {
        br "content"
      }
    end
  end

  def test_error_css_proxy_continue
    assert_raises Keynote::Rumble::Error do
      build_html {
        p.one("test").two
      }
    end
  end

  # The real test here is if @rumble_context is nil in the teardown.
  def test_error_general
    assert_raises RuntimeError do
      build_html {
        div do
          raise
        end
      }
    end
  end
end
