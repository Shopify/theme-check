# frozen_string_literal: true
require "test_helper"

class SyntaxErrorTest < Minitest::Test
  def test_reports_parse_errors
    offenses = analyze_theme(
      ThemeCheck::SyntaxError.new,
      "templates/index.liquid" => <<~END,
        {% include 'muffin'
      END
    )
    assert_offenses(<<~END, offenses)
      Tag '{%' was not properly terminated with regexp: /\\%\\}/ at templates/index.liquid:1
    END
  end

  def test_reports_missing_tag
    offenses = analyze_theme(
      ThemeCheck::SyntaxError.new,
      "templates/index.liquid" => <<~END,
        {% unknown %}
      END
    )
    assert_offenses(<<~END, offenses)
      Unknown tag 'unknown' at templates/index.liquid:1
    END
  end

  def test_reports_lax_warnings_and_continue
    offenses = analyze_theme(
      ThemeCheck::SyntaxError.new,
      "templates/index.liquid" => <<~END,
        {% if collection | size > 0 %}
        {% endif %}
        {% if collection | > 0 %}
        {% endif %}
      END
    )
    assert_offenses(<<~END, offenses)
      Expected end_of_string but found pipe at templates/index.liquid:1
      Expected end_of_string but found pipe at templates/index.liquid:3
    END
  end
end
