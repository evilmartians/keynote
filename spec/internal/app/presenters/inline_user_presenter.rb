# frozen_string_literal: true

class InlineUserPresenter < Keynote::Presenter
  extend Keynote::Inline
  inline :slim, :haml

  def simple_template
    erb
    # Here's some math: <%= 2 + 2 %>
  end

  def ivars
    @greetee = "world"
    erb
    # Hello <%= @greetee %>!
  end

  def locals_from_hash
    erb local: "H"
    # Local <%= local %>
  end

  def locals_from_binding
    local = "H"
    erb binding
    # Local <%= local %>
  end

  def method_calls
    erb
    # <%= locals_from_hash %>
    # <%= locals_from_binding %>
  end

  def error_handling
    erb
    # <% raise "UH OH" %>
  end

  def fix_indentation
    slim
    # .indented_slightly
    #   - (2..4).each do |i|
    #     ' #{i} times
  end

  def erb_escaping
    raw = erb
    # <%= "<script>alert(1);</script>" %>
    escaped = erb
    # <%= "<script>alert(1);</script>".html_safe %>
    raw + escaped
  end

  def slim_escaping
    raw = slim
    # = "<script>alert(1);</script>"
    escaped = slim
    # = "<script>alert(1);</script>".html_safe
    raw + escaped
  end

  def haml_escaping
    raw = haml
    # = "<script>alert(1);</script>"
    escaped = haml
    # = "<script>alert(1);</script>".html_safe
    raw + escaped
  end
end
