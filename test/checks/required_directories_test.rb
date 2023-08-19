# frozen_string_literal: true
require "test_helper"

class RequiredDirectories < Minitest::Test
  def test_does_not_report_missing_directories
    offenses = analyze_theme(
      PlatformosCheck::RequiredDirectories.new,
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
      PlatformosCheck::RequiredDirectories.new,
      "assets/gift-card.js" => "",
      "config/settings_data.json" => "",
      "layout/theme.liquid" => "",
      "sections/footer.liquid" => "",
      "snippets/comment.liquid" => "",
      "templates/index.liquid" => ""
    )

    assert_includes_offense(offenses, "Theme is missing 'locales' directory")
  end

  def test_creates_missing_directories
    theme = make_theme(
      "assets/gift-card.js" => "",
      "config/settings_data.json" => "",
      "layout/theme.liquid" => "",
      "sections/footer.liquid" => "",
      "snippets/comment.liquid" => "",
      "templates/index.liquid" => ""
    )

    analyzer = PlatformosCheck::Analyzer.new(theme, [PlatformosCheck::RequiredDirectories.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    missing_directories = ["locales"]
    assert(missing_directories.all? { |file| theme.storage.directories.include?(file) })
  end
end
