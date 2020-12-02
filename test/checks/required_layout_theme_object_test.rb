# frozen_string_literal: true
require "test_helper"

class RequiredLayoutThemeObjectTest < Minitest::Test
  def test_do_not_report_when_required_objects_are_present
    offenses = analyze_layout_theme(
      <<~END
        {{content_for_header}}
        {{content_for_layout}}
      END
    )

    assert_equal("", offenses.join)
  end

  def test_picks_up_variable_lookups_only
    offenses = analyze_layout_theme(
      <<~END
        {{"a"}}
        {{"1"}}
        {{ false }}
        {{content_for_header}}
        {{content_for_layout}}
      END
    )

    assert_equal("", offenses.join)
  end

  def test_report_offense_on_missing_content_for_header
    offenses = analyze_layout_theme("{{content_for_layout}}")

    assert_equal(
      "layout/theme must include {{content_for_header}} at layout/theme.liquid",
      offenses.join
    )
  end

  def test_report_offense_on_missing_content_for_layout
    offenses = analyze_layout_theme("{{content_for_header}}")

    assert_equal(
      "layout/theme must include {{content_for_layout}} at layout/theme.liquid",
      offenses.join
    )
  end

  private

  def analyze_layout_theme(content)
    analyze_theme(
      ThemeCheck::RequiredLayoutThemeObject.new,
      "layout/theme.liquid" => content
    )
  end
end
