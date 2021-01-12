# frozen_string_literal: true
require "test_helper"

class CorrectorTest < Minitest::Test
  def setup
    @theme = make_theme(
      "templates/index.liquid" => <<~END,
        <p>
          {{1 + 2}}
        </p>
      END
    )
  end

  def test_insert_after_adds_suffix
    node = stub(
      template: @theme["templates/index"],
      line_number: 2,
      range: [4, 8]
    )
    corrector = ThemeCheck::Corrector.new(template: node.template)

    corrector.insert_after(node, " ")
    assert_equal("{{1 + 2 }}", node.template.excerpt(node.line_number))
  end

  def test_insert_before_adds_prefix
    node = stub(
      template: @theme["templates/index"],
      line_number: 2,
      range: [4, 8]
    )
    corrector = ThemeCheck::Corrector.new(template: node.template)

    corrector.insert_before(node, " ")
    assert_equal("{{ 1 + 2}}", node.template.excerpt(node.line_number))
  end

  def test_replace_replaces_markup
    node = stub(
      template: @theme["templates/index"],
      line_number: 2,
      range: [4, 8],
      :markup= => ()
    )
    corrector = ThemeCheck::Corrector.new(template: node.template)

    corrector.replace(node, "3 + 4")
    assert_equal("{{3 + 4}}", node.template.excerpt(node.line_number))
  end

  def test_wrap_adds_prefix_and_suffix
    node = stub(
      template: @theme["templates/index"],
      line_number: 2,
      range: [4, 8]
    )
    corrector = ThemeCheck::Corrector.new(template: node.template)

    corrector.wrap(node, "a", "b")
    assert_equal("{{a1 + 2b}}", node.template.excerpt(node.line_number))
  end
end
