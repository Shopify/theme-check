# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class PositionHelperTest < Minitest::Test
      def setup
        @helper = Object.new
        @helper.extend(PositionHelper)
      end

      def test_convert_from_line_column_to_index
        assert_equal(content.index('a'), @helper.from_line_column_to_index(0, 0, content))
        assert_equal(content.index('e'), @helper.from_line_column_to_index(0, 4, content))
        assert_equal(content.index('h'), @helper.from_line_column_to_index(1, 0, content))
        assert_equal(content.index('m'), @helper.from_line_column_to_index(1, 5, content))
        assert_equal(content.index('r'), @helper.from_line_column_to_index(2, 1, content))
        assert_equal(content.index('z'), @helper.from_line_column_to_index(5, 1, content))
      end

      def test_convert_index_to_line_column
        assert_equal([0, 0], @helper.from_index_to_line_column(content.index('a'), content))
        assert_equal([0, 4], @helper.from_index_to_line_column(content.index('e'), content))
        assert_equal([1, 0], @helper.from_index_to_line_column(content.index('h'), content))
        assert_equal([1, 5], @helper.from_index_to_line_column(content.index('m'), content))
        assert_equal([2, 1], @helper.from_index_to_line_column(content.index('r'), content))
        assert_equal([5, 1], @helper.from_index_to_line_column(content.index('z'), content))
      end

      private

      def content
        <<~LIQUID
          abcdefg
          hijklmnop
          qrs
          tuv
          wx
          yz
        LIQUID
      end
    end
  end
end
