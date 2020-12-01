# frozen_string_literal: true
require "test_helper"

class ParsingHelpersTest < Minitest::Test
  include ThemeCheck::ParsingHelpers

  def test_outside_of_strings
    chunks = []
    outside_of_strings("1'\"2'3\"4\"") { |chunk| chunks << chunk }
    assert_equal(["1", "3"], chunks)
  end
end
