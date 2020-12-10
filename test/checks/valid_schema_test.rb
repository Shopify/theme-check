# frozen_string_literal: true
require "test_helper"

class ValidSchemaTest < Minitest::Test
  def test_detects_json_error
    offenses = analyze_theme(
      ThemeCheck::ValidSchema.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {
        {% endschema %}
      END
    )
    assert_offenses(<<~END, offenses)
      unexpected token at '{ in JSON at sections/product.liquid:1
    END
  end

  def test_valid_json
    offenses = analyze_theme(
      ThemeCheck::ValidSchema.new,
      "sections/product.liquid" => <<~END,
        {% schema %}
          {}
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end
end
