# frozen_string_literal: true
require "test_helper"

class NestedLoopTest < Minitest::Test
  def test_valid
    offenses = analyze_theme(
      ThemeCheck::NestedLoop.new,
      "templates/index.liquid" => <<~END,
      {% for product in collection.products %}
        {% for tag in product.tags %}
        {% endfor %}
      {% endfor %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_sibling_loops
    offenses = analyze_theme(
      ThemeCheck::NestedLoop.new,
      "templates/index.liquid" => <<~END,
      {% for product in collection.products %}
        {% for tag in product.tags %}
        {% endfor %}
        {% for variant in product.product.variants %}
        {% endfor %}
        {% for collection in product.product.product.collections %}
        {% endfor %}
      {% endfor %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_offenses
    offenses = analyze_theme(
      ThemeCheck::NestedLoop.new,
      "templates/index.liquid" => <<~END,
      {% for product in collection.products %}
        {% for tag in product.tags %}
          {% for variant in product.variants %}
            {% for collection in product.collections %}

            {% endfor %}
          {% endfor %}
        {% endfor %}
      {% endfor %}
      END
    )
    assert_offenses(<<~END, offenses)
      Avoid nesting loops more than 2 levels at templates/index.liquid:3
      Avoid nesting loops more than 2 levels at templates/index.liquid:4
    END
  end
end
