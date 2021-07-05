# frozen_string_literal: true
require "liquid"

require_relative "theme_check/version"
require_relative "theme_check/bug"
require_relative "theme_check/exceptions"
require_relative "theme_check/theme_file"
require_relative "theme_check/analyzer"
require_relative "theme_check/check"
require_relative "theme_check/checks_tracking"
require_relative "theme_check/cli"
require_relative "theme_check/disabled_check"
require_relative "theme_check/disabled_checks"
require_relative "theme_check/liquid_check"
require_relative "theme_check/locale_diff"
require_relative "theme_check/asset_file"
require_relative "theme_check/remote_asset_file"
require_relative "theme_check/regex_helpers"
require_relative "theme_check/json_check"
require_relative "theme_check/json_file"
require_relative "theme_check/json_helpers"
require_relative "theme_check/position_helper"
require_relative "theme_check/position"
require_relative "theme_check/language_server"
require_relative "theme_check/checks"
require_relative "theme_check/config"
require_relative "theme_check/node"
require_relative "theme_check/offense"
require_relative "theme_check/printer"
require_relative "theme_check/shopify_liquid"
require_relative "theme_check/storage"
require_relative "theme_check/string_helpers"
require_relative "theme_check/file_system_storage"
require_relative "theme_check/in_memory_storage"
require_relative "theme_check/tags"
require_relative "theme_check/template"
require_relative "theme_check/theme"
require_relative "theme_check/visitor"
require_relative "theme_check/corrector"
require_relative "theme_check/html_node"
require_relative "theme_check/html_visitor"
require_relative "theme_check/html_check"

Dir[__dir__ + "/theme_check/checks/*.rb"].each { |file| require file }

# UTF-8 is the default internal and external encoding, like in Rails & Shopify.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module ThemeCheck
  def self.with_liquid_c_disabled
    if defined?(Liquid::C)
      was_enabled = Liquid::C.enabled
      Liquid::C.enabled = false if was_enabled
    end
    yield
  ensure
    if defined?(Liquid::C) && was_enabled
      Liquid::C.enabled = true
    end
  end
end
