# frozen_string_literal: true
require "test_helper"

class SchemaJsonFormatTest < Minitest::Test
  def test_valid
    offenses = analyze_theme(
      ThemeCheck::SchemaJsonFormat.new,
      "templates/index.liquid" => <<~END,
        {% schema %}
          {
            "hello": "world"
          }
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_offenses
    offenses = analyze_theme(
      ThemeCheck::SchemaJsonFormat.new,
      "templates/index.liquid" => <<~END,
        {% schema %}
          { "hello": "world" }
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      JSON formatting could use some love at templates/index.liquid:1
    END
  end

  def test_fix_offenses
    expected_source = {
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
                "missing": "TODO"
              }
            }
          }
        {% endschema %}
      END
    }

    source = fix_theme(
      ThemeCheck::SchemaJsonFormat.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
            "locales": {
            "en": {
              "title": "Welcome", "missing": "Product"
            },
                "fr": { "title": "Bienvenue", "missing": "TODO" }
            }
          }
        {% endschema %}
      END
    )

    assert_equal(expected_source, source)
  end
end
