# frozen_string_literal: true
require "test_helper"

class ParsingHelpersTest < Minitest::Test
  include PlatformosCheck::ParsingHelpers

  def test_outside_of_strings
    chunks = []
    outside_of_strings("1'\"2'3\"4\"") { |chunk| chunks << chunk }
    assert_equal(["1", "3"], chunks)
  end

  def test_outside_of_strings_with_empty_string
    chunks = []
    outside_of_strings("one: '.', '' | two: ',', '.'") { |chunk| chunks << chunk }
    assert_equal(["one: ", ", ", " | two: ", ", "], chunks)
    chunks = []
    outside_of_strings("1'' '2'3") { |chunk| chunks << chunk }
    assert_equal(["1", " ", "3"], chunks)
  end

  def test_outside_of_strings_with_newline
    chunks = []
    outside_of_strings(<<~CONTENTS) { |chunk| chunks << chunk }
      next: '<i class="icon icon--right-t"></i><span class="icon-fallback__text">Next Page</span>',
      previous: '<i class="icon icon--left-t"></i><span class="icon-fallback__text">Previous Page</span>'
    CONTENTS
    assert_equal(["next: ", ",\nprevious: ", "\n"], chunks)
  end
end
