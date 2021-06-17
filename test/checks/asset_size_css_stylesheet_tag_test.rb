# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeCSSStylesheetTagTest < Minitest::Test
    def test_css_bundles_smaller_than_threshold
      offenses = analyze_theme(
        AssetSizeCSSStylesheetTag.new(threshold_in_bytes: 10000000),
        {
          "assets/theme.css" => <<~JS,
            console.log('hello world');
          JS
          "templates/index.liquid" => <<~END,
            <html>
              <head>
                {{ 'theme.css' | asset_url | stylesheet_tag }}
              </head>
            </html>
          END
        }
      )
      assert_offenses("", offenses)
    end

    def test_css_bundles_bigger_than_threshold
      offenses = analyze_theme(
        AssetSizeCSSStylesheetTag.new(threshold_in_bytes: 2),
        "assets/theme.css" => <<~JS,
          console.log('hello world');
        JS
        "templates/index.liquid" => <<~END,
          <html>
            <head>
              {{ 'theme.css' | asset_url | stylesheet_tag }}
            </head>
          </html>
        END
      )
      assert_offenses(<<~END, offenses)
        CSS on every page load exceeding compressed size threshold (2 Bytes). at templates/index.liquid:3
      END
    end

    def test_no_stylesheet
      offenses = analyze_theme(
        AssetSizeCSSStylesheetTag.new(threshold_in_bytes: 100000),
        "templates/index.liquid" => <<~END,
          <html>
            <head>
            </head>
          </html>
        END
      )
      assert_offenses("", offenses)
    end
  end
end
