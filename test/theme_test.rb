# frozen_string_literal: true
require "test_helper"

class ThemeTest < Minitest::Test
  def setup
    @themes = [
      make_theme(
        "templates/index.liquid" => "",
        "snippets/product.liquid" => "",
        "sections/article-template/template.liquid" => "",
        "locales/en.default.json" => "",
      ),
      make_in_memory_theme(
        "templates/index.liquid" => "",
        "snippets/product.liquid" => "",
        "sections/article-template/template.liquid" => "",
        "locales/en.default.json" => "",
      ),
    ]
  end

  def test_all
    @themes.each do |theme|
      assert_equal(4, theme.all.size)
    end
  end

  def test_liquid
    @themes.each do |theme|
      assert_equal(3, theme.liquid.size)
    end
  end

  def test_json
    @themes.each do |theme|
      assert_equal(1, theme.json.size)
    end
  end

  def test_by_name
    @themes.each do |theme|
      assert_equal("templates/index", theme["templates/index"].name)
      assert_equal("sections/article-template/template", theme["sections/article-template/template"].name)
    end
  end

  def test_templates
    @themes.each do |theme|
      assert_equal(["templates/index"], theme.templates.map(&:name))
    end
  end

  def test_snippets
    @themes.each do |theme|
      assert_equal(["snippets/product"], theme.snippets.map(&:name))
    end
  end

  def test_sections
    @themes.each do |theme|
      assert_equal(["sections/article-template/template"], theme.sections.map(&:name))
    end
  end

  def test_default_locale_json
    @themes.each do |theme|
      assert_equal(theme["locales/en.default"], theme.default_locale_json)
    end
  end

  def test_default_locale
    @themes.each do |theme|
      assert_equal("en", theme.default_locale)
    end
  end

  def test_ignore
    theme = ThemeCheck::Theme.new(make_theme(
      "templates/index.liquid" => "",
      "ignored/product.liquid" => "",
      "ignored/nested/product.liquid" => "",
      "locales/en.default.json" => "",
      "locales/nested/en.default.json" => "",
    ).root, ignored_patterns: [
      "ignored/*",
      "*.json",
    ])

    assert_equal([], theme.json.map(&:name))
    assert_equal(["templates/index"], theme.liquid.map(&:name))
  end
end
