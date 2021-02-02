# frozen_string_literal: true
require_relative "parsing_helpers"

module ThemeCheck
  class LiquidCheck < Check
    extend ChecksTracking
    include ParsingHelpers

    def add_offense(message, node: nil, template: node&.template, markup: nil, line_number: nil, position: nil, &block)
      offenses << Offense.new(check: self, message: message, template: template, node: node, markup: markup, line_number: line_number, position: position, correction: block)
    end
  end
end
