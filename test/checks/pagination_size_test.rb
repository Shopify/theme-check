# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class PaginationSizeTest < Minitest::Test
    def test_no_offense_for_good_behaviour
      offenses = analyze_theme(
        PaginationSize.new(max_size: 50),
        "templates/index.liquid" => <<~END,
          {% paginate products by 50 %}
          {% endpaginate %}

          {%- paginate products by 50 -%}
          {%- endpaginate -%}

          <!-- setting size -->
          {%- paginate collection.products by section.settings.products_per_page -%}
          {% endpaginate %}
          {% schema %}
            {
                "name": "test",
                "settings": [
                    {
                        "type": "number",
                        "id": "products_per_page",
                        "label": "Products per Page",
                        "default": 12
                    }
                ]
            }
            {% endschema %}
        END
      )
      assert_offenses("", offenses)
    end

    def test_flag_use_of_size_greater_than_limit
      offenses = analyze_theme(
        PaginationSize.new(max_size: 50),
        "templates/index.liquid" => <<~END,
          {%- paginate collection.products by 999 -%}
          {%- endpaginate -%}
          {% paginate collection.products by 999 %}
          {% endpaginate %}
        END
      )
      assert_offenses(<<~END, offenses)
        Use a smaller pagination size at templates/index.liquid:1
        Use a smaller pagination size at templates/index.liquid:3
      END
    end

    def test_flag_use_of_setting_value
      offenses = analyze_theme(
        PaginationSize.new(max_size: 50),
        "templates/index.liquid" => <<~END,
          <!-- setting size -->
          {%- paginate collection.products by section.settings.products_per_page -%}
          {% endpaginate %}
          {% schema %}
            {
                "name": "test",
                "settings": [
                    {
                        "type": "number",
                        "id": "products_per_page",
                        "label": "Products per Page",
                        "default": 51
                    }
                ]
            }
          {% endschema %}
        END
      )
      assert_offenses(<<~END, offenses)
        Use a smaller pagination size at templates/index.liquid:2
      END
    end
  end
end
