# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class PositionHelperTest < Minitest::Test
      include PositionHelper

      def test_convert_from_row_column_to_index
        assert_equal(content.index('a'), from_row_column_to_index(content, 0, 0))
        assert_equal(content.index('e'), from_row_column_to_index(content, 0, 4))
        assert_equal(content.index('h'), from_row_column_to_index(content, 1, 0))
        assert_equal(content.index('m'), from_row_column_to_index(content, 1, 5))
        assert_equal(content.index('r'), from_row_column_to_index(content, 2, 1))
        assert_equal(content.index('z'), from_row_column_to_index(content, 5, 1))
      end

      def test_convert_index_to_row_column
        assert_equal([0, 0], from_index_to_row_column(content, content.index('a')))
        assert_equal([0, 4], from_index_to_row_column(content, content.index('e')))
        assert_equal([1, 0], from_index_to_row_column(content, content.index('h')))
        assert_equal([1, 5], from_index_to_row_column(content, content.index('m')))
        assert_equal([2, 1], from_index_to_row_column(content, content.index('r')))
        assert_equal([5, 1], from_index_to_row_column(content, content.index('z')))
      end

      def test_handles_empty_content_gracefully
        assert_equal([0, 0], from_index_to_row_column('', 0))
        assert_equal([0, 0], from_index_to_row_column('', 100))
        assert_equal([0, 0], from_index_to_row_column('', -100))
        assert_equal(0, from_row_column_to_index('', 0, 0))
        assert_equal(0, from_row_column_to_index('', 100, 100))
        assert_equal(0, from_row_column_to_index('', -100, -100))
      end

      def test_handles_out_of_bounds_gracefully
        # returns the first character
        assert_equal([0, 0], from_index_to_row_column(content, -1))

        # returns the last character (the newline)
        assert_equal([5, 2], from_index_to_row_column(content, 100))

        # clamps row + col
        assert_equal(content.index('a'), from_row_column_to_index(content, -1, -1))
        assert_equal(content.index('a'), from_row_column_to_index(content, 0, -1))
        assert_equal(content.index("\n"), from_row_column_to_index(content, 0, 20))
        assert_equal(content.index('h'), from_row_column_to_index(content, 1, -1))
        assert_equal(content.index("\n", content.index("\n") + 1), from_row_column_to_index(content, 1, 20))
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
