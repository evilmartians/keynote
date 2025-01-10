# frozen_string_literal: true

module Foo
  class BarPresenter < Keynote::Presenter
    presents :model

    def generate_div
      build_html do
        div.hi! do
          link_to "#", "Hello"
        end
      end
    end
  end
end
