# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class PaginationSizeTest < Minitest::Test
    def test_no_offense_for_good_behaviour
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
        "templates/index.liquid" => <<~END,
          {% paginate products by 50 %}
          {% endpaginate %}

          {%- paginate products by 50 -%}
          {%- endpaginate -%}

          <!-- setting size -->
          {%- paginate collection.products by section.settings.products_per_page -%}
          {%- endpaginate -%}

          {%- paginate collection.products by section.settings.products_per_page_as_string -%}
          {% endpaginate %}

          <!-- dynamic size -->
          {%- assign products_per_page = section.settings.products_per_page -%}
          {%- paginate collection.products by products_per_page -%}
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
                    },
                    {
                        "type": "text",
                        "id": "products_per_page_as_string",
                        "label": "Products per Page",
                        "default": "12"
                    }
                ]
            }
          {% endschema %}
        END
      )
      assert_offenses("", offenses)
    end

    def test_flag_use_of_size_greater_than_max
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
        "templates/index.liquid" => <<~END,
          {%- paginate collection.products by 999 -%}
          {%- endpaginate -%}
          {% paginate collection.products by 999 %}
          {% endpaginate %}
        END
      )
      assert_offenses(<<~END, offenses)
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:1
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:3
      END
    end

    def test_flag_use_of_size_less_than_min
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
        "templates/index.liquid" => <<~END,
          {%- paginate collection.products by 0 -%}
          {%- endpaginate -%}
          {% paginate collection.products by 0 %}
          {% endpaginate %}
        END
      )
      assert_offenses(<<~END, offenses)
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:1
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:3
      END
    end

    def test_flag_use_of_size_is_integer
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
        "templates/index.liquid" => <<~END,
          {%- paginate collection.products by 1.5 -%}
          {%- endpaginate -%}
          {% paginate collection.products by 1.5 %}
          {% endpaginate %}
        END
      )
      assert_offenses(<<~END, offenses)
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:1
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:3
      END
    end

    def test_flag_use_of_setting_value
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
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
        Pagination size must be a positive integer between 1 and 50 at templates/index.liquid:2
      END
    end

    def test_flag_use_of_missing_setting_value
      offenses = analyze_theme(
        PaginationSize.new(min_size: 1, max_size: 50),
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
                        "label": "Products per Page"
                    }
                ]
            }
          {% endschema %}
        END
      )
      assert_offenses(<<~END, offenses)
        Default pagination size should be defined in the section settings at templates/index.liquid:2
      END
    end
  end
end
