# frozen_string_literal: true
require "test_helper"

class ConvertIncludeToRenderTest < Minitest::Test
  def test_reports_on_include
    offenses = analyze_theme(
      ThemeCheck::ConvertIncludeToRender.new,
      "templates/index.liquid" => <<~END,
        {% include 'templates/foo.liquid' %}
      END
    )
    assert_offenses(<<~END, offenses)
      `include` is deprecated - convert it to `render` at templates/index.liquid:1
    END
  end

  def test_does_not_reports_on_render
    offenses = analyze_theme(
      ThemeCheck::ConvertIncludeToRender.new,
      "templates/index.liquid" => <<~END,
        {% render 'templates/foo.liquid' %}
      END
    )
    assert_offenses("", offenses)
  end
end
