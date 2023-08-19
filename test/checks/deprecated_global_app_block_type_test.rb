# frozen_string_literal: true

module PlatformosCheck
  class DeprecatedGlobalAppBlockTypeTest < Minitest::Test
    def test_reject_invalid_global_app_block_type_in_section_schemas
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
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

    def test_reject_invalid_global_app_block_type_in_conditional_statement
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% for block in section.blocks %}
            {% if block.type = "@global" %}
              {% render block %}
            {% elsif "@global" == block.type %}
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
        Deprecated '@global' block type, use '@app' block type instead. at sections/product.liquid
        Deprecated '@global' block type defined in the schema, use '@app' block type instead. at sections/product.liquid:7
      END
    end

    def test_reject_invalid_global_app_block_type_in_switch_case_statement
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% for block in section.blocks %}
            {% case block.type %}
              {% when "@global" %}
                {% render block %}
              {% else %}
            {% endcase %}
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
        Deprecated '@global' block type defined in the schema, use '@app' block type instead. at sections/product.liquid:8
      END
    end

    def test_reject_invalid_global_app_block_type_defined_as_liquid_variable
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          {% assign invalid = "@global" %}
          {% assign valid = "@app" %}
          {% schema %}
            {
              "name": "Product section"
            }
          {% endschema %}
        END
      )

      assert_offenses(<<~END, offenses)
        Deprecated '@global' block type, use '@app' block type instead. at sections/product.liquid:1
      END
    end

    def test_does_not_reject_global_string_used_outside_liquid_control_flow_statements
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
        "sections/product.liquid" => <<~END,
          <p> This is "@global" </p>
          <script> var i = "@global" </script>
          {% schema %}
            {
              "name": "Product section"
            }
          {% endschema %}
        END
      )

      assert_offenses("", offenses)
    end

    def test_accepts_valid_global_app_block_type
      offenses = analyze_theme(
        PlatformosCheck::DeprecatedGlobalAppBlockType.new,
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
