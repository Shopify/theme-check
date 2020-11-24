# frozen_string_literal: true
require "test_helper"

class LiquidTagTest < Minitest::Test
  def test_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag,
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Use {% liquid ... %} to write multiple tags at templates/index.liquid:1
    END
  end

  def test_ignores_non_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag,
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
    assert_equal("", offenses.join)
  end
end
