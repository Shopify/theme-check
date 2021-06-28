# frozen_string_literal: true
require_relative "parsing_helpers"

module ThemeCheck
  class LiquidCheck < Check
    extend ChecksTracking
    include ParsingHelpers
  end
end
