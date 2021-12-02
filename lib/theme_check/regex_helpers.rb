# frozen_string_literal: true

module ThemeCheck
  module RegexHelpers
    LIQUID_TAG = /#{Liquid::TagStart}.*?#{Liquid::TagEnd}/om
    LIQUID_VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    LIQUID_TAG_OR_VARIABLE = /#{LIQUID_TAG}|#{LIQUID_VARIABLE}/om
    HTML_LIQUID_PLACEHOLDER = /≬[0-9a-z\n]+[#\n]*≬/m
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
    OPENING_LIQUID_TAG_AND_LEADING_WHITESPACE = /({%-|{%)(\s?|\n)+(?=\w)/
    TRAILING_WHITESPACE_AND_CLOSING_LIQUID_TAG = /(\s?|\n)+(?=(-%}|%}))(-%}|%})/

    def matches(s, re)
      start_at = 0
      matches = []
      while (m = s.match(re, start_at))
        matches.push(m)
        start_at = m.end(0)
      end
      matches
    end
  end
end
