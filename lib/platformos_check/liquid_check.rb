# frozen_string_literal: true
require_relative "parsing_helpers"

module PlatformosCheck
  class LiquidCheck < Check
    extend ChecksTracking
    include ParsingHelpers
  end
end
