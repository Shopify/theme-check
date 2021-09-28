# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class CodeActionHelperTest < Minitest::Test
      include CodeActionHelper

      Offense = Struct.new(:range)

      def test_offense_in_range
        # True when highlighting inside the error
        assert(offense_in_range?(Offense.new(5...10), (6..8)))

        # True when highlighting the error itself
        assert(offense_in_range?(Offense.new(5...10), (5...10)))

        # True when highlighting around the error
        assert(offense_in_range?(Offense.new(5...10), (1...15)))

        # True for zero length range inside the range
        assert(offense_in_range?(Offense.new(5...10), (5...5)))

        # False for no overlap
        refute(offense_in_range?(Offense.new(5...10), (1...5)))

        # False for partial overlap
        refute(offense_in_range?(Offense.new(5...10), (1...7)))

        # False for zero length range inside the range
        refute(offense_in_range?(Offense.new(5...10), (10...10)))
      end
    end
  end
end
