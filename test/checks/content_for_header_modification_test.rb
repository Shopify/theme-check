# frozen_string_literal: true
require "test_helper"

class ContentForHeaderModificationTest < Minitest::Test
  def test_reports_use_of_filter
    offenses = analyze_theme(
      ThemeCheck::ContentForHeaderModification.new,
      "layout/theme.liquid" => <<~END,
        {{ content_for_header | split: ',' }}
      END
    )
    assert_offenses(<<~END, offenses)
      Do not rely on the content of `content_for_header` at layout/theme.liquid:1
    END
  end

  def test_reports_assign
    offenses = analyze_theme(
      ThemeCheck::ContentForHeaderModification.new,
      "layout/theme.liquid" => <<~END,
        {% assign x = content_for_header %}
      END
    )
    assert_offenses(<<~END, offenses)
      Do not rely on the content of `content_for_header` at layout/theme.liquid:1
    END
  end

  def test_reports_capture
    offenses = analyze_theme(
      ThemeCheck::ContentForHeaderModification.new,
      "layout/theme.liquid" => <<~END,
        {% capture x %}
          {{ content_for_header }}
        {% endcapture %}
      END
    )
    assert_offenses(<<~END, offenses)
      Do not rely on the content of `content_for_header` at layout/theme.liquid:2
    END
  end

  def test_reports_echo
    offenses = analyze_theme(
      ThemeCheck::ContentForHeaderModification.new,
      "layout/theme.liquid" => <<~END,
        {% liquid
          echo content_for_header | split: ','
        %}
      END
    )
    assert_offenses(<<~END, offenses)
      Do not rely on the content of `content_for_header` at layout/theme.liquid:2
    END
  end

  def test_do_not_report_normal_use
    offenses = analyze_theme(
      ThemeCheck::ContentForHeaderModification.new,
      "layout/theme.liquid" => <<~END,
        {{ content_for_header }}
      END
    )
    assert_offenses("", offenses)
  end
end
