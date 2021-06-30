# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeCSSTest < Minitest::Test
    def setup
      @extension_files = {
        "assets/app.css" => "* { color: green } ",
        "blocks/app.liquid" => <<~BLOCK,

          {% schema %}
          {
            "stylesheet": "app.css"
          }
          {% endschema %}
        BLOCK
      }
    end

    def test_css_smaller_than_threshold
      offenses = analyze_theme(
        AssetSizeAppBlockCSS.new(threshold_in_bytes: 10_000_000),
        @extension_files,
      )
      assert_offenses("", offenses)
    end

    def test_css_larger_than_threshold
      offenses = analyze_theme(
        AssetSizeAppBlockCSS.new(threshold_in_bytes: 1),
        @extension_files,
      )
      assert_offenses(<<~END, offenses)
        CSS in Theme App Extension blocks exceeds compressed size threshold (1 Bytes) at blocks/app.liquid:2
      END
    end
  end
end
