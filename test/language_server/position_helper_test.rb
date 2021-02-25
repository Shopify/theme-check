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
        assert_equal(content.index('a'), @helper.from_line_column_to_index(content, 0, 0))
        assert_equal(content.index('e'), @helper.from_line_column_to_index(content, 0, 4))
        assert_equal(content.index('h'), @helper.from_line_column_to_index(content, 1, 0))
        assert_equal(content.index('m'), @helper.from_line_column_to_index(content, 1, 5))
        assert_equal(content.index('r'), @helper.from_line_column_to_index(content, 2, 1))
        assert_equal(content.index('z'), @helper.from_line_column_to_index(content, 5, 1))
      end

      def test_convert_index_to_line_column
        assert_equal([0, 0], @helper.from_index_to_line_column(content, content.index('a')))
        assert_equal([0, 4], @helper.from_index_to_line_column(content, content.index('e')))
        assert_equal([1, 0], @helper.from_index_to_line_column(content, content.index('h')))
        assert_equal([1, 5], @helper.from_index_to_line_column(content, content.index('m')))
        assert_equal([2, 1], @helper.from_index_to_line_column(content, content.index('r')))
        assert_equal([5, 1], @helper.from_index_to_line_column(content, content.index('z')))
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
