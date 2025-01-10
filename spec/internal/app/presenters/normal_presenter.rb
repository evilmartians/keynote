# frozen_string_literal: true

class NormalPresenter < Keynote::Presenter
  presents :model

  def some_bad_js
    "<script>alert('pwnt');</script>"
  end

  def some_bad_html
    build_html do
      div { text some_bad_js }
      div { some_bad_js }
      div some_bad_js
    end
  end
end
