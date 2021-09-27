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

  class Bogus < ThemeCheck::Check
    MESSAGE = "This is bogus"
  end

  def test_source_excerpt
    node = stub(
      theme_file: @theme["templates/index"],
      line_number: 2,
      markup: "1 + 2",
    )
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)

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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)

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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node, correction: proc { |c| c.insert_after(node, "abc") })
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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)
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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)
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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)
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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)
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
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node)
    assert_equal(0, offense.start_row)
    assert_equal(0, offense.end_row)
    assert_equal(0, offense.start_column)
    assert_equal(3, offense.end_column)
  end

  def test_equal
    assert_equal(ThemeCheck::Offense.new(check: Bogus.new, line_number: 2), ThemeCheck::Offense.new(check: Bogus.new, line_number: 2))
    refute_equal(ThemeCheck::Offense.new(check: Bogus.new, line_number: 1), ThemeCheck::Offense.new(check: Bogus.new, line_number: 2))
  end
end
