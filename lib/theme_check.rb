# frozen_string_literal: true
require "liquid"

require_relative "theme_check/analyzer"
require_relative "theme_check/check"
require_relative "theme_check/checks"
require_relative "theme_check/node"
require_relative "theme_check/offense"
require_relative "theme_check/printer"
require_relative "theme_check/tags"
require_relative "theme_check/template"
require_relative "theme_check/theme"
require_relative "theme_check/visitor"

Dir[__dir__ + "/theme_check/checks/*.rb"].each { |file| require file }
