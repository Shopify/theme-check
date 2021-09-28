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

  def test_ignores_key_included_in_schema
    offenses = analyze_theme(
      ThemeCheck::TranslationKeyExists.new,
      "sections/product.liquid" => <<~END,
        {{"submit" | t}}
        {% schema %}
          {
            "locales": {
              "en": {
                "submit": "Subscribe"
              }
            }
          }
        {% endschema %}
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

  def test_creates_missing_keys
    theme = make_theme(
      "locales/en.default.json" => JSON.dump({}),
      "templates/index.liquid" => <<~END,
        {{"unknownkey" | t}}
        {{"unknown.nested.key" | t}}
        {{"unknownkey" | translate}}
      END
    )

    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::TranslationKeyExists.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    expected = { "unknownkey" => "TODO", "unknown" => { "nested" => { "key" => "TODO" } } }
    actual = theme.default_locale_json.content

    assert_equal(expected, actual)
  end

  def test_creates_nested_missing_keys
    theme = make_theme(
      "locales/en.default.json" => JSON.dump({
        key: "TODO",
        nested: { key: "TODO" },
        samplekey: { unknownkey: { key: "TODO" } },
      }),
      "templates/index.liquid" => <<~END,
        {{"unknownkey" | t}}
        {{"nested.unknownkey" | t}}
        {{"samplekey.unknownkey.sample" | translate}}
        {{"samplekey.example.sample" | translate}}
      END
    )

    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::TranslationKeyExists.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    expected = {
      "key" => "TODO",
      "nested" => {
        "key" => "TODO",
        "unknownkey" => "TODO",
      },
      "samplekey" => {
        "unknownkey" => {
          "key" => "TODO",
          "sample" => "TODO",
        },
        "example" => {
          "sample" => "TODO",
        },
      },
      "unknownkey" => "TODO",
    }
    actual = theme.default_locale_json.content

    assert_equal(expected, actual)
  end
end
