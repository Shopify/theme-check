# frozen_string_literal: true
require "test_helper"

class NestedSnippetTest < Minitest::Test
  def test_reports_deep_nesting
    offenses = analyze_theme(
      ThemeCheck::NestedSnippet.new(max_nesting_level: 2),
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
      END
      "snippets/one.liquid" => <<~END,
        {% include 'two' %}
      END
      "snippets/two.liquid" => <<~END,
        {% include 'three' %}
      END
      "snippets/three.liquid" => <<~END,
        {% include 'four' %}
      END
      "snippets/four.liquid" => <<~END,
        ok
      END
    )
    assert_offenses(<<~END, offenses)
      Too many nested snippets at snippets/one.liquid:1
      Too many nested snippets at templates/index.liquid:1
    END
  end

  def test_do_not_report_limit_nesting
    offenses = analyze_theme(
      ThemeCheck::NestedSnippet.new(max_nesting_level: 2),
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
      END
      "snippets/one.liquid" => <<~END,
        {% include 'two' %}
      END
      "snippets/two.liquid" => <<~END,
        ok
      END
    )
    assert_offenses("", offenses)
  end
end
