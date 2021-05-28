# frozen_string_literal: true
require "test_helper"

class ParserBlockingScriptTagTest < Minitest::Test
  def test_script_tag_filter
    offenses = analyze_theme(
      ThemeCheck::ParserBlockingScriptTag.new,
      "templates/index.liquid" => <<~END,
        {{ 'foo.js' | asset_url | script_tag }}
      END
    )
    assert_offenses(<<~END, offenses)
      The script_tag filter is parser-blocking. Use a script tag with the async or defer attribute for better performance at templates/index.liquid:1
    END
  end
end
