# frozen_string_literal: true
require "test_helper"

class ValidSchemaTest < Minitest::Test
  def test_detects_json_error
    offenses = analyze_theme(
      PlatformosCheck::ValidSchema.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      Invalid syntax in JSON at sections/product.liquid:1
    END
  end

  def test_valid_json
    offenses = analyze_theme(
      PlatformosCheck::ValidSchema.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {}
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end
end
