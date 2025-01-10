# frozen_string_literal: true

class InlineUserPresenter < Keynote::Presenter
  extend Keynote::Inline
  inline :slim, :haml

  def simple_template(template = %(Here's some math: <%= 2 + 2 %>))
    erb do
      <<~ERB
        #{template}
      ERB
    end
  end

  def ivars
    @greetee = "world"
    erb do
      <<~ERB
        Hello <%= @greetee %>!
      ERB
    end
  end

  def locals_from_hash
    erb(local: "H") do
      <<~ERB
        Local <%= local %>
      ERB
    end
  end

  def method_calls
    erb do
      <<~ERB
        <%= locals_from_hash %>
      ERB
    end
  end

  def error_handling
    erb do
      <<~ERB
        <% raise "UH OH" %>
      ERB
    end
  end

  def fix_indentation
    slim do
<<-'SLIM' # rubocop:disable Layout/IndentationWidth
 .indented_slightly
   - (2..4).each do |i|
     ' #{i} times
SLIM
    end
  end

  def erb_escaping
    raw = erb do
      <<~ERB
        <%= "<script>alert(1);</script>" %>
      ERB
    end
    escaped = erb do
      <<~ERB
        <%= "<script>alert(1);</script>".html_safe %>
      ERB
    end

    raw + escaped
  end

  def slim_escaping
    raw = slim do
      <<~SLIM
        = "<script>alert(1);</script>"
      SLIM
    end

    escaped = slim do
      <<~SLIM
        = "<script>alert(1);</script>".html_safe
      SLIM
    end

    raw + escaped
  end

  def haml_escaping
    raw = haml do
      <<~HAML
        = "<script>alert(1);</script>"
      HAML
    end
    escaped = haml do
      <<~HAML
        = "<script>alert(1);</script>".html_safe
      HAML
    end

    raw + escaped
  end
end
