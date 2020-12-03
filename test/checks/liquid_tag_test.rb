# frozen_string_literal: true
require "test_helper"

class LiquidTagTest < Minitest::Test
  def test_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
      END
    )
    assert_offenses(<<~END, offenses)
      Use {% liquid ... %} to write multiple tags at templates/index.liquid:1
    END
  end

  def test_ignores_non_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        Hello
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_ignores_inside_liquid_tag
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% liquid
          assign x = 1
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
        %}
      END
    )
    assert_offenses("", offenses)
  end
end
