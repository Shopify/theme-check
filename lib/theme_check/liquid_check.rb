# frozen_string_literal: true
require_relative "parsing_helpers"

module ThemeCheck
  class LiquidCheck < Check
    extend ChecksTracking
    include ParsingHelpers

    # TODO: remove this once all regex checks are migrate to HtmlCheck# TODO: remove this once all regex checks are migrate to HtmlCheck
    TAG = /#{Liquid::TagStart}.*?#{Liquid::TagEnd}/om
    VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
    QUOTED_LIQUID_ATTRIBUTE = %r{
      '(?:#{TAG}|#{VARIABLE}|[^'])*'| # any combination of tag/variable or non straight quote inside straight quotes
      "(?:#{TAG}|#{VARIABLE}|[^"])*"  # any combination of tag/variable or non double quotes inside double quotes
    }omix
    ATTR = /[a-z0-9-]+/i
    HTML_ATTRIBUTE = /#{ATTR}(?:=#{QUOTED_LIQUID_ATTRIBUTE})?/omix
    HTML_ATTRIBUTES = /(?:#{HTML_ATTRIBUTE}|\s)*/omix
  end
end
