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
    )
  end

  class Bogus < ThemeCheck::Check
    MESSAGE = "This is bogus"
  end

  def test_source_excerpt
    node = stub(
      template: @theme["templates/index"],
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
      template: @theme["templates/long"],
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
      template: @theme["templates/index"],
      line_number: 2,
      markup: "1 + 2",
      range: [4, 10]
    )
    offense = ThemeCheck::Offense.new(check: Bogus.new, node: node, correction: proc { |c| c.insert_after(node, "abc") })
    offense.correct

    assert_equal("{{ 1 + 2 abc}}", node.template.excerpt(node.line_number))
  end
end
