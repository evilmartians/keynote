# frozen_string_literal: true

require "ruby-next"
require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

require "keynote/core"
require "keynote/version"
require "keynote/rumble"
require "keynote/inline"
require "keynote/presenter"
require "keynote/controller"
require "keynote/helper"
require "keynote/railtie" if defined?(Rails::Railtie)
require "keynote/cache"
