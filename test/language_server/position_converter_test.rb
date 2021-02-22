# frozen_string_literal: true
require "test_helper"

class PositionConverterTest < Minitest::Test
  def test_convert_from_line_column_to_index
    assert_equal(content.index('a'), ThemeCheck::PositionConverter.from_line_column_to_index(0, 0, content))
    assert_equal(content.index('e'), ThemeCheck::PositionConverter.from_line_column_to_index(0, 4, content))
    assert_equal(content.index('h'), ThemeCheck::PositionConverter.from_line_column_to_index(1, 0, content))
    assert_equal(content.index('m'), ThemeCheck::PositionConverter.from_line_column_to_index(1, 5, content))
    assert_equal(content.index('r'), ThemeCheck::PositionConverter.from_line_column_to_index(2, 1, content))
    assert_equal(content.index('z'), ThemeCheck::PositionConverter.from_line_column_to_index(5, 1, content))
  end

  def test_convert_index_to_line_column
    assert_equal([0, 0], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('a'), content))
    assert_equal([0, 4], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('e'), content))
    assert_equal([1, 0], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('h'), content))
    assert_equal([1, 5], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('m'), content))
    assert_equal([2, 1], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('r'), content))
    assert_equal([5, 1], ThemeCheck::PositionConverter.from_index_to_line_column(content.index('z'), content))
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
