# frozen_string_literal: true
require "test_helper"

class ParsingHelpersTest < Minitest::Test
  include ThemeCheck::ParsingHelpers

  def test_outside_of_strings
    chunks = []
    outside_of_strings("1'\"2'3\"4\"5") { |chunk, start| chunks << [chunk, start] }
    assert_equal([
      ["1", 0],
      ["3", 5],
      ["5", 9],
    ], chunks)
  end

  def test_no_strings_outside_of_strings
    chunks = []
    outside_of_strings("hello, bye") { |chunk, start| chunks << [chunk, start] }
    assert_equal([
      ["hello, bye", 0],
    ], chunks)
  end
end
