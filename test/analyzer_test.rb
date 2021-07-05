# frozen_string_literal: true
require "test_helper"

class AnalyzerTest < Minitest::Test
  def setup
    @theme = make_theme(
      "assets/theme.js" => "",
      "assets/theme.css" => "",
      "templates/index.liquid" => "",
      "snippets/product.liquid" => "",
      "sections/article-template/template.liquid" => "",
      "locales/en.default.json" => "",
    )
    @analyzer = ThemeCheck::Analyzer.new(@theme)
  end

  def test_analyze_theme
    @analyzer.analyze_theme
    refute_empty(@analyzer.offenses)
  end

  def test_analyze_files
    @analyzer.analyze_files(@theme.all)
    refute_empty(@analyzer.offenses)
  end
end
