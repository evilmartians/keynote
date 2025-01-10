# frozen_string_literal: true

require "test_helper"

class Foo::BarPresenterTest < Keynote::TestCase
  setup do
    @presenter = Foo::BarPresenter.new(view, :model)
  end

  test "presenter has view context" do
    assert_equal "<div id=\"hi\"><a href=\"Hello\">#</a></div>",
      @presenter.generate_div
  end
end
