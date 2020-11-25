# frozen_string_literal: true
require "test_helper"

class ParseErrorTest < Minitest::Test
  def test_reports_parse_errors
    offenses = analyze_theme(
      ThemeCheck::ParseError.new,
      "templates/index.liquid" => <<~END,
        {% include 'muffin'
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Tag '{%' was not properly terminated with regexp: /\\%\\}/ at templates/index.liquid:1
    END
  end

  def test_reports_missing_tag
    offenses = analyze_theme(
      ThemeCheck::ParseError.new,
      "templates/index.liquid" => <<~END,
        {% unknown %}
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Unknown tag 'unknown' at templates/index.liquid:1
    END
  end
end
