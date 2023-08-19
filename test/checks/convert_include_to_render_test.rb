# frozen_string_literal: true
require "test_helper"

class ConvertIncludeToRenderTest < Minitest::Test
  def test_reports_on_include
    offenses = analyze_theme(
      PlatformosCheck::ConvertIncludeToRender.new,
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
      PlatformosCheck::ConvertIncludeToRender.new,
      "templates/index.liquid" => <<~END,
        {% render 'templates/foo.liquid' %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_corrects_include
    skip
    sources = fix_theme(
      PlatformosCheck::ConvertIncludeToRender.new,
      "templates/index.liquid" => <<~END,
        {% include 'foo.liquid' %}
        {% assign greeting = "hello world" %}
        {% include 'greeting.liquid' %}
      END
      "snippets/greeting.liquid" => <<~END,
        {{ greeting }}
      END
    )
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% render 'foo.liquid' %}
        {% assign greeting = "hello world" %}
        {% render 'greeting.liquid', greeting: greeting %}
      END
      "snippets/greeting.liquid" => <<~END,
        {{ greeting }}
      END
    }
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
