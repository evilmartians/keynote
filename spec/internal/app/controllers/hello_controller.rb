# frozen_string_literal: true

class HelloController < ActionController::Base
  def world
    render text: "Hello world!", layout: false
  end
end
