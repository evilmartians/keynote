# frozen_string_literal: true

module Keynote
  module TestPresentMethod
    def present(*objects, &blk)
      Keynote.present(view, *objects, &blk)
    end
    alias_method :k, :present
  end
end
