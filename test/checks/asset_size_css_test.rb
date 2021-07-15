# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeCSSTest < Minitest::Test
    def test_href_to_file_size
      theme = make_theme({
        "assets/theme.css" => "* { color: green !important; }",
      })

      assert_has_file_size("{{ 'theme.css' | asset_url }}", theme)
      RemoteAssetFile.any_instance.expects(:gzipped_size).times(3).returns(42)
      assert_has_file_size("https://example.com/foo.css", theme)
      assert_has_file_size("http://example.com/foo.css", theme)
      assert_has_file_size("//example.com/foo.css", theme)

      refute_has_file_size("{{ 'this_file_does_not_exist.css' | asset_url }}", theme)
      refute_has_file_size("{% if on_product %}https://hello.world{% else %}https://hi.world{% endif %}", theme)
    end

    def assert_has_file_size(href, theme)
      check = AssetSizeCSS.new
      check.theme = theme
      fs = check.href_to_file_size(href)
      assert(fs, "expected `#{href}` to have a file size.")
    end

    def refute_has_file_size(href, theme)
      check = AssetSizeCSS.new
      check.theme = theme
      fs = check.href_to_file_size(href)
      refute(fs, "didn't expect to get a file size for `#{href}`.")
    end

    def test_css_bundles_smaller_than_threshold
      offenses = analyze_theme(
        AssetSizeCSS.new(threshold_in_bytes: 10000000),
        {
          "assets/theme.css" => <<~JS,
            console.log('hello world');
          JS
          "templates/index.liquid" => <<~END,
            <html>
              <head>
                <link href="{{ 'theme.css' | asset_url }}" rel="stylesheet">
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
        AssetSizeCSS.new(threshold_in_bytes: 2),
        "assets/theme.css" => <<~JS,
          console.log('hello world');
        JS
        "templates/index.liquid" => <<~END,
          <html>
            <head>
              <link href="{{ 'theme.css' | asset_url }}" rel="stylesheet">
            </head>
          </html>
        END
      )
      assert_offenses(<<~END, offenses)
        CSS on every page load exceeding compressed size threshold (2 Bytes) at templates/index.liquid:3
      END
    end
  end
end
