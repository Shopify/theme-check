# frozen_string_literal: true
require "test_helper"

class SchemaJsonFormatTest < Minitest::Test
  def test_valid
    offenses = analyze_theme(
      PlatformosCheck::SchemaJsonFormat.new(start_level: 1),
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

  def test_does_not_report_on_invalid_json
    offenses = analyze_theme(
      PlatformosCheck::SchemaJsonFormat.new(start_level: 1),
      "templates/index.liquid" => <<~END,
        {% schema %}
          {
            "hello": "world",
          }
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_offenses
    offenses = analyze_theme(
      PlatformosCheck::SchemaJsonFormat.new(start_level: 1),
      "templates/index.liquid" => <<~END,
        {% schema %}
          { "hello": "world" }
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      JSON formatting could be improved at templates/index.liquid:1
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
      PlatformosCheck::SchemaJsonFormat.new(start_level: 1),
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
