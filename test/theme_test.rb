# frozen_string_literal: true
require "test_helper"

class ThemeTest < Minitest::Test
  def setup
    @theme = make_theme(
      "templates/index.liquid" => "",
      "snippets/product.liquid" => "",
      "sections/article-template/template.liquid" => "",
    )
  end

  def test_all
    assert_equal(3, @theme.all.size)
  end

  def test_by_name
    assert_equal("templates/index", @theme["templates/index"].name)
    assert_equal("sections/article-template/template", @theme["sections/article-template/template"].name)
  end

  def test_templates
    assert_equal(["templates/index"], @theme.templates.map(&:name))
  end

  def test_snippets
    assert_equal(["snippets/product"], @theme.snippets.map(&:name))
  end

  def test_sections
    assert_equal(["sections/article-template/template"], @theme.sections.map(&:name))
  end
end
