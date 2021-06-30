# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeJavaScriptTest < Minitest::Test
    def setup
      @extension_files = {
        "assets/app.js" => "alert('hello world')",
        "blocks/app.liquid" => <<~BLOCK,

          {% schema %}
          {
            "javascript": "app.js"
          }
          {% endschema %}
        BLOCK
      }
    end

    def test_js_smaller_than_threshold
      offenses = analyze_theme(
        AssetSizeAppBlockJavaScript.new(threshold_in_bytes: 10_000_000),
        @extension_files,
      )
      assert_offenses("", offenses)
    end

    def test_js_larger_than_threshold
      offenses = analyze_theme(
        AssetSizeAppBlockJavaScript.new(threshold_in_bytes: 1),
        @extension_files,
      )
      assert_offenses(<<~END, offenses)
        JavaScript in Theme App Extension blocks exceeds compressed size threshold (1 Bytes) at blocks/app.liquid:2
      END
    end
  end
end
