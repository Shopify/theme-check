# frozen_string_literal: true
require "test_helper"

class RequiredDirectories < Minitest::Test
  def test_does_not_report_missing_directories
    offenses = analyze_theme(
      ThemeCheck::RequiredDirectories.new,
      "assets/gift-card.js" => "",
      "config/settings_data.json" => "",
      "layout/theme.liquid" => "",
      "locales/es.json" => "",
      "sections/footer.liquid" => "",
      "snippets/comment.liquid" => "",
      "templates/index.liquid" => ""
    )

    assert_empty(offenses)
  end

  def test_reports_missing_directories
    offenses = analyze_theme(
      ThemeCheck::RequiredDirectories.new,
      "assets/gift-card.js" => "",
      "config/settings_data.json" => "",
      "layout/theme.liquid" => "",
      "sections/footer.liquid" => "",
      "snippets/comment.liquid" => "",
      "templates/index.liquid" => ""
    )

    assert_includes_offense(offenses, "Theme is missing 'locales' directory")
  end
end
