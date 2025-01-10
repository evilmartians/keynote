# frozen_string_literal: true

require "bundler/setup"

require "rails"
require "keynote"

require "benchmark/ips"

class MyPresenter < Keynote::Presenter
  extend Keynote::Inline
  inline :erb

  def my_string
    "a" + "b" + "c"
  end

  def rumble
    a_local = 1000

    build_html do
      div.foobar.baz! do
        p { my_string }
        p { a_local }
      end
    end
  end

  def erb_hash
    a_local = 1000

    erb a_local: a_local
    # <div class="foobar" id="baz">
    #   <p><%= my_string %></p>
    #   <p><%= a_local %></p>
    # </div>
  end

  def erb_binding
    a_local = 1000

    erb binding
    # <div class="foobar" id="baz">
    #   <p><%= my_string %></p>
    #   <p><%= a_local %></p>
    # </div>
  end

  def raw_erb_template(tpl)
    tpl.render(self, {a_local: 1000})
  end
end

source = %(
  <div class="foobar" id="baz">
    <p><%= my_string %></p>
    <p><%= a_local %></p>
  </div>
)
template = Keynote::Inline::Template.new(
  source, "raw_erb_template",
  ActionView::Template.handler_for_extension(:erb),
  locals: [:a_local],
  format: :erb
)

presenter = MyPresenter.new(:view)

Benchmark.ips do |x|
  x.config(time: 10, warmup: 5)

  x.report("rumble") { presenter.rumble }
  x.report("erb_hash") { presenter.erb_hash }
  x.report("erb_binding") { presenter.erb_binding }
  x.report("raw_erb_template") { presenter.raw_erb_template(template) }
  x.compare!
end
