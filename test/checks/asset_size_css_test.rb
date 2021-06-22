# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeCSSTest < Minitest::Test
    def test_link_tag_regex
      # using quotes
      assert_href(<<~EXPECTED.strip, <<~SOURCE)
        "{{ 'theme.css' | asset_url }}"
      EXPECTED
        <link href="{{ 'theme.css' | asset_url }}" rel="stylesheet">
      SOURCE

      # using straight quotes
      assert_href(<<~EXPECTED.strip, <<~SOURCE)
        '{{ 'theme.css' | asset_url }}'
      EXPECTED
        <link rel="stylesheet" href='{{ 'theme.css' | asset_url }}'>
      SOURCE

      # with follow up boolean attribute
      assert_href(<<~EXPECTED.strip, <<~SOURCE)
        "/theme.css"
      EXPECTED
        <link rel="stylesheet" href="/theme.css" disabled>
      SOURCE

      # with whitespace after boolean attribute
      assert_href(<<~EXPECTED.strip, <<~SOURCE)
        "theme.css"
      EXPECTED
        <link
          rel="stylesheet"
          href="theme.css"
          media="all"
          disabled
        ></script>
      SOURCE

      # with whitespace inside variable
      assert_href(<<~EXPECTED.strip, <<~SOURCE)
        '{{
            'theme.css' | asset_url
          }}'
      EXPECTED
        <link
          href='{{
            'theme.css' | asset_url
          }}'
          rel="stylesheet"
        ></script>
      SOURCE
    end

    def assert_href(expected, source)
      match = AssetSizeCSS::LINK_TAG_HREF.match(source)
      assert(match, "Expected to extract #{expected} from #{source}")
      assert_equal(expected, match[:href])
    end

    def test_stylesheet_extractor
      check = AssetSizeCSS.new
      stylesheets = check.stylesheets(<<~SOURCE)
        <html>
          <head>
            <link href="{{ '1.css' | asset_url }}" rel="stylesheet" disabled>
            <link href="{{ '2.css' | asset_url }}" rel="stylesheet" media="all">
            <link href="3.css" rel="stylesheet">
            <link rel="stylesheet" href="4.css">
            {{ '5.css' | asset_url | stylesheet_tag }}
            <link rel="preload" href="not-this.css">
          </head>
        </html>
      SOURCE

      expected = [
        "{{ '1.css' | asset_url }}",
        "{{ '2.css' | asset_url }}",
        "3.css",
        "4.css",
        "{{ '5.css' | asset_url | stylesheet_tag }}",
      ]

      assert_equal(expected, stylesheets.map(&:href))
    end

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
              {{ 'theme.css' | asset_url | stylesheet_tag }}
            </head>
          </html>
        END
      )
      assert_offenses(<<~END, offenses)
        CSS on every page load exceeds compressed size threshold (2 Bytes). at templates/index.liquid:3
        CSS on every page load exceeds compressed size threshold (2 Bytes). at templates/index.liquid:4
      END
    end
  end
end
