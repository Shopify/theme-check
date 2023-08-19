# frozen_string_literal: true
require "test_helper"
require "minitest/focus"

class MatchingTranslationsTest < Minitest::Test
  def test_no_default_noops
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.json" => JSON.dump(a: "a"),
      "locales/fr.json" => JSON.dump(b: "b"),
    )
    assert_offenses("", offenses)
  end

  def test_invalid_default_json_noops
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => "}",
      "locales/fr.json" => JSON.dump(b: "b"),
    )
    assert_offenses("", offenses)
  end

  def test_non_hash_ignored
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump({}),
      "locales/fr.json" => JSON.dump([]),
    )
    assert_offenses("", offenses)
  end

  def test_nested_matching_translations
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: { world: "Hello, world" }
      ),
      "locales/fr.json" => JSON.dump(
        hello: { world: "Bonjour, monde" }
      ),
      "locales/es-ES.json" => JSON.dump(
        hello: { world: "Hola, mundo" }
      ),
    )
    assert_offenses("", offenses)
  end

  def test_report_missing_keys
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(hello: "Hello"),
      "locales/fr.json" => JSON.dump({}),
    )

    assert_offenses(<<~END, offenses)
      Missing translation keys: hello at locales/fr.json
    END
  end

  def test_report_missing_keys_nested
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        "hello": { "world": "Hello, world" }
      ),
      "locales/fr.json" => JSON.dump(
        "hello": {}
      ),
    )
    assert_offenses(<<~END, offenses)
      Missing translation keys: hello.world at locales/fr.json
    END
  end

  def test_report_extra_keys
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump({}),
      "locales/fr.json" => JSON.dump(hello: "Bonjour"),
    )
    assert_offenses(<<~END, offenses)
      Extra translation keys: hello at locales/fr.json
    END
  end

  def test_report_extra_keys_nested
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: {}
      ),
      "locales/fr.json" => JSON.dump(
        hello: { world: "Bonjour, monde" }
      ),
    )
    assert_offenses(<<~END, offenses)
      Extra translation keys: hello.world at locales/fr.json
    END
  end

  def test_report_extra_keys_for_mismatched_types
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: "Hello"
      ),
      "locales/fr.json" => JSON.dump(
        hello: { world: "Bonjour, monde" }
      ),
    )
    assert_offenses(<<~END, offenses)
      Extra translation keys: hello.world at locales/fr.json
    END
  end

  def test_report_missing_keys_for_mismatched_types
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: { world: "Hello, World" }
      ),
      "locales/fr.json" => JSON.dump(
        hello: "Bonjour"
      ),
    )
    assert_offenses(<<~END, offenses)
      Missing translation keys: hello.world at locales/fr.json
    END
  end

  def test_ignore_pluralization
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: {
          one: "Hello, you",
          other: "Hello, y'all",
        }
      ),
      "locales/fr.json" => JSON.dump(
        hello: {
          zero: "Je suis seul :(",
          few: "Salut, petit gang",
        }
      ),
    )

    assert_offenses("", offenses)
  end

  def test_ignore_shopify_provided
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: "Hello",
        shopify: {
          checkout: {
            general: {
              page_title: 'Checkout',
            },
          },
        },
      ),
      "locales/fr.json" => JSON.dump(
        hello: "Bonjour",
        shopify: {
          sentence: {
            words_connector: "hello world",
          },
        },
      ),
    )

    assert_offenses("", offenses)
  end

  def test_ignore_schema_json_locale_files
    offenses = analyze_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: "Hello",
        shopify: {
          checkout: {
            general: {
              page_title: 'Checkout',
            },
          },
        },
      ),
      "locales/fr.schema.json" => JSON.dump(
        hello: "Bonjour",
      ),
    )

    assert_offenses("", offenses)
  end

  def test_shape_change
    sources = fix_theme(
      PlatformosCheck::MatchingTranslations.new,
      "locales/en.default.json" => JSON.dump(
        hello: {
          another_key: "world",
          shape_change: "world",
        },
      ),
      "locales/fr.json" => JSON.dump(
        hello: "Bonjour",
      ),
    )
    expected_sources = {
      "locales/en.default.json" => JSON.dump(
        hello: {
          another_key: "world",
          shape_change: "world",
        },
      ),
      "locales/fr.json" => JSON.dump(
        hello: {
          another_key: "TODO",
          shape_change: "TODO",
        },
      ),
    }
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
