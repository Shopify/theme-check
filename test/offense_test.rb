# frozen_string_literal: true
require "test_helper"

class OffenseTest < Minitest::Test
  def setup
    @theme = make_theme(
      "templates/index.liquid" => <<~END,
        <p>
          {{ 1 + 2 }}
        </p>
      END
      "templates/long.liquid" => <<~END,
        <span class="form__message">{% include 'icon-error' %}{{ form.errors.translated_fields['email'] | capitalize }} {{ form.errors.messages['email'] }}.</span>
      END
      "templates/multiline.liquid" => <<~END,
        {% render 'product-card',
          product: product,
          show: true
        %}
      END
    )
  end

  class Bogus < PlatformosCheck::Check
    MESSAGE = "This is bogus"
  end

  def test_source_excerpt
    node = stub(
      theme_file: @theme["templates/index"],
      line_number: 2,
      markup: "1 + 2",
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)

    assert_equal("{{ 1 + 2 }}", offense.source_excerpt)
    assert_equal("1 + 2", offense.markup)
    assert_equal(3, offense.markup_start_in_excerpt)
  end

  def test_truncated_source_excerpt
    node = stub(
      theme_file: @theme["templates/long"],
      line_number: 1,
      markup: "include 'icon-error'",
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)

    assert_equal("<span class=\"form__message\">{% include 'icon-error' %}{{ form.errors.translated_fields['email'] | capitalize }} {{ fo...", offense.source_excerpt)
    assert_equal("include 'icon-error'", offense.markup)
    assert_equal(31, offense.markup_start_in_excerpt)
  end

  def test_correct
    node = stub(
      theme_file: @theme["templates/index"],
      line_number: 2,
      start_index: @theme["templates/index"].source.index('1'),
      end_index: @theme["templates/index"].source.index('2 ') + 2,
      markup: "1 + 2",
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node, correction: proc { |c| c.insert_after(node, "abc") })
    offense.correct

    node.theme_file.write
    assert_equal("{{ 1 + 2 abc}}", node.theme_file.source_excerpt(2))
  end

  def test_location
    node = stub(
      theme_file: @theme["templates/index"],
      line_number: 2,
      markup: "1 + 2",
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(1, offense.start_row)
    assert_equal(1, offense.end_row)
    assert_equal(5, offense.start_column)
    assert_equal(10, offense.end_column)
  end

  def test_multiline_markup_location
    node = stub(
      theme_file: @theme["templates/multiline"],
      line_number: 1,
      markup: "render 'product-card',\n  product: product,\n  show: true",
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(0, offense.start_row)
    assert_equal(3, offense.start_column)
    assert_equal(2, offense.end_row)
    assert_equal(12, offense.end_column)
  end

  def test_multiline_markup_location_with_trailing_new_line
    markup = "render 'product-card',\n  product: product,\n  show: true\n\n\n"
    node = stub(
      theme_file: make_theme("stub.liquid" => "{% #{markup}%}")["stub"],
      line_number: 1,
      markup: markup
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(0, offense.start_row)
    assert_equal(3, offense.start_column)
    assert_equal(5, offense.end_row)
    assert_equal(0, offense.end_column)
  end

  def test_multiline_markup_location_with_multiple_new_lines_back_to_back
    markup = "render 'product-card',\n\n\n  product: product"
    node = stub(
      theme_file: make_theme("stub.liquid" => "{% #{markup}%}")["stub"],
      line_number: 1,
      markup: markup
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(0, offense.start_row)
    assert_equal(3, offense.start_column)
    assert_equal(3, offense.end_row)
    assert_equal(18, offense.end_column)
  end

  def test_location_without_markup
    node = stub(
      theme_file: @theme["templates/index"],
      line_number: 1,
      markup: nil,
    )
    offense = PlatformosCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(0, offense.start_row)
    assert_equal(0, offense.end_row)
    assert_equal(0, offense.start_column)
    assert_equal(3, offense.end_column)
  end

  def test_equal
    assert_equal(PlatformosCheck::Offense.new(check: Bogus.new, line_number: 2), PlatformosCheck::Offense.new(check: Bogus.new, line_number: 2))
    refute_equal(PlatformosCheck::Offense.new(check: Bogus.new, line_number: 1), PlatformosCheck::Offense.new(check: Bogus.new, line_number: 2))
  end

  def test_offense_in_range
    theme_file = stub(source: "supp world! how are you doing today?")
    offense = PlatformosCheck::Offense.new(
      check: Bogus.new,
      markup: "world",
      theme_file: theme_file,
      line_number: 1
    )

    # Showing the assumption
    assert_equal(offense.range, 5...10)

    # True when highlighting inside the error
    assert(offense.in_range?(5..5))
    assert(offense.in_range?(6...8))

    # True when highlighting the error itself
    assert(offense.in_range?(5...10))

    # True when highlighting around the error
    assert(offense.in_range?(1...15))
    assert(offense.in_range?(1...10))
    assert(offense.in_range?(5...15))

    # True for zero length range inside the range
    assert(offense.in_range?(5...5))
    assert(offense.in_range?(6...6))

    # False for no overlap
    refute(offense.in_range?(1...5))

    # False for partial overlap
    refute(offense.in_range?(1...7))

    # False for zero length range outside the range
    refute(offense.in_range?(10...10))
  end

  def test_offense_in_range_zero_length_offense
    theme_file = stub(source: '{ "json_file_without_line_numbers": "ok" }')
    offense = PlatformosCheck::Offense.new(
      check: Bogus.new,
      theme_file: theme_file,
    )

    # Showing the assumption
    assert_equal(offense.range, 0..0)

    # True when highlighting over the error
    assert(offense.in_range?(0..0))
    assert(offense.in_range?(0...0))

    # False for no overlap
    refute(offense.in_range?(1...5))
  end
end
