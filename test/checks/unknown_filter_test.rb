# frozen_string_literal: true
require "test_helper"

class UnknownFilterTest < Minitest::Test
  def test_reports_on_unknown_filter
    offenses = analyze_theme(
      ThemeCheck::UnknownFilter.new,
      "templates/index.liquid" => <<~END,
        {{ "foo" | bar }}
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Undefined filter `bar` at templates/index.liquid:1
    END
  end

  def test_reports_on_unknown_filter_chained_with_known_filters
    offenses = analyze_theme(
      ThemeCheck::UnknownFilter.new,
      "templates/index.liquid" => <<~END,
        {{ "foo" | append: ".js" | bar }}
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Undefined filter `bar` at templates/index.liquid:1
    END
  end

  def test_reports_does_not_report_on_known_filter
    offenses = analyze_theme(
      ThemeCheck::UnknownFilter.new,
      "templates/index.liquid" => <<~END,
        {{ "foo" | upcase }}
      END
    )
    assert_empty(offenses.join)
  end

  def test_reports_does_not_report_on_chain_of_known_filter
    offenses = analyze_theme(
      ThemeCheck::UnknownFilter.new,
      "templates/index.liquid" => <<~END,
        {{ "foo" | append: ".js" | upcase }}
      END
    )
    assert_empty(offenses.join)
  end
end
