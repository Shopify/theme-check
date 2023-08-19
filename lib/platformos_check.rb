# frozen_string_literal: true
require "liquid"

require_relative "platformos_check/version"
require_relative "platformos_check/bug"
require_relative "platformos_check/exceptions"
require_relative "platformos_check/schema_helper"
require_relative "platformos_check/theme_file_rewriter"
require_relative "platformos_check/theme_file"
require_relative "platformos_check/liquid_file"
require_relative "platformos_check/asset_file"
require_relative "platformos_check/json_file"
require_relative "platformos_check/analyzer"
require_relative "platformos_check/check"
require_relative "platformos_check/checks_tracking"
require_relative "platformos_check/liquid_check"
require_relative "platformos_check/html_check"
require_relative "platformos_check/json_check"
require_relative "platformos_check/cli"
require_relative "platformos_check/disabled_check"
require_relative "platformos_check/disabled_checks"
require_relative "platformos_check/locale_diff"
require_relative "platformos_check/remote_asset_file"
require_relative "platformos_check/regex_helpers"
require_relative "platformos_check/json_helpers"
require_relative "platformos_check/position_helper"
require_relative "platformos_check/position"
require_relative "platformos_check/checks"
require_relative "platformos_check/config"
require_relative "platformos_check/node"
require_relative "platformos_check/tags"
require_relative "platformos_check/liquid_node"
require_relative "platformos_check/html_node"
require_relative "platformos_check/offense"
require_relative "platformos_check/printer"
require_relative "platformos_check/json_printer"
require_relative "platformos_check/shopify_liquid"
require_relative "platformos_check/string_helpers"
require_relative "platformos_check/storage"
require_relative "platformos_check/file_system_storage"
require_relative "platformos_check/in_memory_storage"
require_relative "platformos_check/theme"
require_relative "platformos_check/corrector"
require_relative "platformos_check/liquid_visitor"
require_relative "platformos_check/html_visitor"
require_relative "platformos_check/language_server"

Dir[__dir__ + "/platformos_check/checks/*.rb"].each { |file| require file }

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module PlatformosCheck
  def self.debug?
    ENV["PLATFORMOS_CHECK_DEBUG"] == "true"
  end

  def self.debug_log_file
    ENV["PLATFORMOS_CHECK_DEBUG_LOG_FILE"]
  end

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
