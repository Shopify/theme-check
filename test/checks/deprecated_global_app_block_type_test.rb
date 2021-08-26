# frozen_string_literal: true

module ThemeCheck
  class DeprecatedGlobalAppBlockTypeTest < Minitest::Test
    def test_reject_invalid_global_app_block_type_in_section_schemas
      offenses = analyze_theme(
        ThemeCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% schema %}
            {
              "name": "Product section",
              "blocks": [{"type": "@global"}]
            }
          {% endschema %}
        END
      )

      assert_offenses(<<~END, offenses)
        Deprecated '@global' block type defined in the schema, use '@app' block type instead. at sections/product.liquid:1
      END
    end

    def test_reject_invalid_global_app_block_type_in_the_section_body
      offenses = analyze_theme(
        ThemeCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% for block in section.blocks %}
            {% if block.type = "@global" %}
              {% render block %}
            {% endif %}
          {% endfor %}
          {% schema %}
            {
              "name": "Product section",
              "blocks": [{"type": "@global"}]
            }
          {% endschema %}
        END
      )

      assert_offenses(<<~END, offenses)
        Deprecated '@global' block type, use '@app' block type instead. at sections/product.liquid
        Deprecated '@global' block type defined in the schema, use '@app' block type instead. at sections/product.liquid:6
      END
    end

    def test_accepts_valid_global_app_block_type
      offenses = analyze_theme(
        ThemeCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% for block in section.blocks %}
            {% if block.type = "@app" %}
              {% render block %}
            {% endif %}
          {% endfor %}
          {% schema %}
            {
              "name": "Product section",
              "blocks": [{"type": "@app"}]
            }
          {% endschema %}
        END
      )

      assert_offenses("", offenses)
    end
  end
end
