# frozen_string_literal: true
require "test_helper"

class MatchingSchemaTranslationsTest < Minitest::Test
  def test_matching
    offenses = analyze_theme(
      ThemeCheck::MatchingSchemaTranslations.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
            "name": {
              "en": "Hello",
              "fr": "Bonjour"
            },
            "settings": [
              {
                "id": "product",
                "label": {
                  "en": "Product",
                  "fr": "Produit"
                }
              }
            ]
          }
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_missing
    offenses = analyze_theme(
      ThemeCheck::MatchingSchemaTranslations.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
            "name": {
              "en": "Hello",
              "fr": "Bonjour"
            },
            "settings": [
              {
                "id": "product",
                "label": {
                  "en": "Product"
                }
              }
            ]
          }
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      settings.product.label missing translations for fr at sections/product.liquid:1
    END
  end

  def test_creates_missing
    theme = make_theme(
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
            "name": {
              "en": "Hello",
              "fr": "Bonjour"
            },
            "settings": [
              {
                "id": "product",
                "label": {
                  "en": "Product",
                }
              }
            ]
          }
        {% endschema %}
      END
    )

    analyzer = ThemeCheck::Analyzer.new(theme, [ThemeCheck::TranslationKeyExists.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    expected = {
      "name" => {
        "en" => "Hello",
        "fr" => "Bonjour"
      },
      "settings" => [{
          "id" => "product",
          "label" => {
            "en" => "Product",
            "fr" => "Produit",
          }
      }]
    }
    #make sure expected and actual are of the same type
    actual = theme.storage.read("sections/product.liquid")
    
    assert_offenses(<<~END, offenses)
      settings.product.label missing translations for fr at sections/product.liquid:1
    END
  end

  def test_locales
    offenses = analyze_theme(
      ThemeCheck::MatchingSchemaTranslations.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
            "locales": {
              "en": {
                "title": "Welcome",
                "missing": "Product"
              },
              "fr": {
                "title": "Bienvenue",
                "extra": "Extra"
              }
            }
          }
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      Extra translation keys: locales.fr.extra at sections/product.liquid:1
      Missing translation keys: locales.fr.missing at sections/product.liquid:1
    END
  end
end
