# frozen_string_literal: true
require "test_helper"

class TranslationKeyExistsTest < Minitest::Test
  def test_noop_without_default_locale
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "templates/index.liquid" => <<~END,
        {{"notfound" | t}}
      END
    )
    assert_offenses("", offenses)
  end

  def test_noop_with_invalid_default_locale
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "locales/en.default.json" => "{",
      "templates/index.liquid" => <<~END,
        {{"notfound" | t}}
      END
    )
    assert_offenses("", offenses)
  end

  def test_ignores_existing_key
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "locales/en.default.json" => JSON.dump(
        key: "",
        nested: { key: "" }
      ),
      "templates/index.liquid" => <<~END,
        {{"key" | t}}
        {{"nested.key" | t}}
      END
    )

    assert_offenses("", offenses)
  end

  def test_reports_unknown_key
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "locales/en.default.json" => JSON.dump({}),
      "templates/index.liquid" => <<~END,
        {{"unknownkey" | t}}
        {{"unknown.nested.key" | t}}
        {{"unknownkey" | translate}}
      END
    )

    assert_offenses(<<~END, offenses)
      'unknownkey' does not have a matching entry in 'locales/en.default.json' at templates/index.liquid:1
      'unknown.nested.key' does not have a matching entry in 'locales/en.default.json' at templates/index.liquid:2
      'unknownkey' does not have a matching entry in 'locales/en.default.json' at templates/index.liquid:3
    END
  end

  def test_counts_shopify_provided_translations_as_defined
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "locales/en.default.json" => JSON.dump({}),
      "templates/index.liquid" => <<~END,
        {{ 'shopify.sentence.words_connector' | t }}
      END
    )

    assert_offenses('', offenses)
  end
end
