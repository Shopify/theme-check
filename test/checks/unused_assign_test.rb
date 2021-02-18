# frozen_string_literal: true
require "test_helper"

class UnusedAssignTest < Minitest::Test
  def test_reports_unused_assigns
    offenses = analyze_theme(
      ThemeCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      `x` is never used at templates/index.liquid:1
    END
  end

  def test_do_not_report_used_assigns
    offenses = analyze_theme(
      ThemeCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {{ a }}
        {% assign b = 1 %}
        {{ 'a' | t: b }}
        {% assign c = 1 %}
        {{ 'a' | t: tags: c }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_do_not_report_assigns_used_before_defined
    offenses = analyze_theme(
      ThemeCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% unless a %}
          {% assign a = 1 %}
        {% endunless %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_do_not_report_assigns_used_in_includes
    offenses = analyze_theme(
      ThemeCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {% include 'using' %}
      END
      "snippets/using.liquid" => <<~END,
        {{ a }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_recursion_in_includes
    offenses = analyze_theme(
      ThemeCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {% include 'one' %}
      END
      "snippets/one.liquid" => <<~END,
        {% include 'two' %}
        {{ a }}
      END
      "snippets/two.liquid" => <<~END,
        {% if some_end_condition %}
          {% include 'one' %}
        {% endif %}
      END
    )
    assert_offenses("", offenses)
  end
end
