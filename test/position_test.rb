# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class PositionTest < Minitest::Test
    def setup
      @contents = [
        "0123\n",
        "0123\n",
        "0123",
      ].join('')
    end

    def test_positions_are_valid
      position = Position.new('23', @contents, 2)
      assert_equal(5 + 2, position.start_index)
      assert_equal(5 + 4, position.end_index)
      assert_equal(1, position.start_row)
      assert_equal(2, position.start_column)
      assert_equal(1, position.end_row)
      assert_equal(4, position.end_column)

      position = Position.new("3\n01", @contents, 2)
      assert_equal(5 + 3, position.start_index)
      assert_equal(5 + 5 + 2, position.end_index)
      assert_equal(1, position.start_row)
      assert_equal(3, position.start_column)
      assert_equal(2, position.end_row)
      assert_equal(2, position.end_column)
    end

    # Can't find needle = highlight line
    def test_cant_find_needle
      position = Position.new("nope", @contents, 2)
      assert_equal(5, position.start_index)
      assert_equal(9, position.end_index)
      assert_equal(1, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(1, position.end_row)
      assert_equal(4, position.end_column)
    end

    def test_line_number_too_small_returns_first_line
      position = Position.new(nil, @contents, -1)
      assert_equal(0, position.start_index)
      assert_equal(4, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(4, position.end_column)

      position = Position.new("nope", @contents, -1)
      assert_equal(0, position.start_index)
      assert_equal(4, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(4, position.end_column)
    end

    def test_line_number_too_large_returns_last_line
      position = Position.new(nil, @contents, 150)
      assert_equal(5 + 5, position.start_index)
      assert_equal(5 + 5 + 4, position.end_index)
      assert_equal(2, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(2, position.end_row)
      assert_equal(3, position.end_column)

      position = Position.new("nope", @contents, 150)
      assert_equal(5 + 5, position.start_index)
      assert_equal(5 + 5 + 4, position.end_index)
      assert_equal(2, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(2, position.end_row)
      assert_equal(3, position.end_column)
    end

    # No contents = [0,0]
    def test_positions_handles_missing_content_gracefully
      position = Position.new('23', nil, 2)
      assert_equal(0, position.start_index)
      assert_equal(0, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(0, position.end_column)
    end

    # Missing needle = highlight line
    def test_positions_handles_missing_needle_gracefully
      position = Position.new(nil, @contents, 2)
      assert_equal(5, position.start_index)
      assert_equal(9, position.end_index)
      assert_equal(1, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(1, position.end_row)
      assert_equal(4, position.end_column)
    end

    # Missing line number = first occurence of markup in string
    def test_positions_handles_missing_line_number_gracefully
      position = Position.new('23', @contents, nil)
      assert_equal(2, position.start_index)
      assert_equal(4, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(2, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(4, position.end_column)
    end

    # Missing needle + contents = [0, 0]
    def test_positions_handles_missing_needle_and_content_gracefully
      position = Position.new(nil, nil, 2)
      assert_equal(0, position.start_index)
      assert_equal(0, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(0, position.end_column)
    end

    # Missing needle + line_number = [0, 0]
    def test_positions_handles_missing_needle_and_line_number_gracefully
      position = Position.new(nil, @contents, nil)
      assert_equal(0, position.start_index)
      assert_equal(0, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(0, position.end_column)
    end

    # Missing contents + line_number = [0, 0]
    def test_positions_handles_missing_contents_and_line_number_gracefully
      position = Position.new('23', nil, nil)
      assert_equal(0, position.start_index)
      assert_equal(0, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(0, position.end_column)
    end

    def test_missing_everything
      position = Position.new(nil, nil, nil)
      assert_equal(0, position.start_index)
      assert_equal(0, position.end_index)
      assert_equal(0, position.start_row)
      assert_equal(0, position.start_column)
      assert_equal(0, position.end_row)
      assert_equal(0, position.end_column)
    end
  end
end
