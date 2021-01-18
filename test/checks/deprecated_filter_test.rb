# frozen_string_literal: true
require "test_helper"

class DeprecatedFilterTest < Minitest::Test
  def test_reports_on_deprecate_filter
    offenses = analyze_theme(
      ThemeCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        color: {{ settings.color_name | hex_to_rgba: 0.5 }};
      END
    )
    assert_offenses(<<~END, offenses)
      Deprecated filter `hex_to_rgba`, consider using an alternative: `color_to_rgb`, `color_modify` at templates/index.liquid:1
    END
  end

  def test_does_not_report_on_filter
    offenses = analyze_theme(
      ThemeCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        color: {{ '#7ab55c' | color_to_rgb }};
      END
    )
    assert_offenses("", offenses)
  end
end
