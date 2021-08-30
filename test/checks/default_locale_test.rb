# frozen_string_literal: true
require "test_helper"

class DefaultLocaleTest < Minitest::Test
  def test_default_locale_file
    offenses = analyze_theme(
      ThemeCheck::DefaultLocale.new,
      "locales/en.default.json" => "{}"
    )
    assert(offenses.empty?)
  end

  def test_default_file_outside_locales
    offenses = analyze_theme(
      ThemeCheck::DefaultLocale.new,
      "data/en.default.json" => "{}"
    )
    refute(offenses.empty?)
  end

  def test_creates_default_file
    theme = make_theme(
      "templates/index.liquid" => <<~END,
        <p>
          {{1 + 2}}
        </p>
      END
    )
    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::DefaultLocale.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses
    assert(theme.default_locale_json)
  end
end
