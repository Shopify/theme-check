# frozen_string_literal: true
require "test_helper"

class MissingTemplateTest < Minitest::Test
  def test_reports_missing_snippet
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
        {% render 'two' %}
      END
    )
    assert_offenses(<<~END, offenses)
      'snippets/one.liquid' is not found at templates/index.liquid:1
      'snippets/two.liquid' is not found at templates/index.liquid:2
    END
  end

  def test_do_not_report_if_snippet_exists
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% include 'one' %}
        {% render 'two' %}
      END
      "snippets/one.liquid" => <<~END,
        hey
      END
      "snippets/two.liquid" => <<~END,
        there
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_missing_section
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% section 'one' %}
      END
    )
    assert_offenses(<<~END, offenses)
      'sections/one.liquid' is not found at templates/index.liquid:1
    END
  end

  def test_do_not_report_if_section_exists
    offenses = analyze_theme(
      ThemeCheck::MissingTemplate.new,
      "templates/index.liquid" => <<~END,
        {% section 'one' %}
      END
      "sections/one.liquid" => <<~END,
        hey
      END
    )
    assert_offenses("", offenses)
  end
end
