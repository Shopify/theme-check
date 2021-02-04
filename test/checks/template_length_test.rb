# frozen_string_literal: true
require "test_helper"

class TemplateLengthTest < Minitest::Test
  def test_finds_unused
    offenses = analyze_theme(
      ThemeCheck::TemplateLength.new(max_length: 10),
      "templates/long.liquid" => <<~END,
        #{"\n" * 10}
      END
      "templates/short.liquid" => <<~END,
        #{"\n" * 9}
      END
    )
    assert_offenses(<<~END, offenses)
      Template has too many lines [11/10] at templates/long.liquid
    END
  end

  def test_excludes_lines_inside_schema
    offenses = analyze_theme(
      ThemeCheck::TemplateLength.new(max_length: 10, exclude_schema: true),
      "sections/long.liquid" => <<~END,
        {% schema %}
          #{"\n" * 10}
        {% endschema %}
      END
    )
    assert_offenses("", offenses)
  end
end
