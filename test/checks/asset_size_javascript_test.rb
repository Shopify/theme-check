# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class AssetSizeJavaScriptTest < Minitest::Test
    def test_script_tag_src_regex
      # using quotes
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        "{{ 'theme.js' | asset_url }}"
      EXPECTED
        <script src="{{ 'theme.js' | asset_url }}"></script>
      SOURCE

      # using straight quotes
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        '{{ 'theme.js' | asset_url }}'
      EXPECTED
        <script src='{{ 'theme.js' | asset_url }}'></script>
      SOURCE

      # with follow up boolean attribute
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        "/theme.js"
      EXPECTED
        <script src="/theme.js" defer></script>
      SOURCE

      # with follow up attribute + value
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        'theme.js'
      EXPECTED
        <script src='theme.js' defer="defer"></script>
      SOURCE

      # with whitespace after boolean attribute
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        'theme.js'
      EXPECTED
        <script
          src='theme.js'
          defer
        ></script>
      SOURCE

      # with whitespace inside variable
      assert_src(<<~EXPECTED.strip, <<~SOURCE)
        '{{
            'theme.js' | asset_url
          }}'
      EXPECTED
        <script
          src='{{
            'theme.js' | asset_url
          }}'
          defer
        ></script>
      SOURCE
    end

    def assert_src(expected, source)
      match = AssetSizeJavaScript::SCRIPT_TAG_SRC.match(source)
      assert(match, "Expected to extract #{expected} from #{source}")
      assert_equal(expected, match[:src])
    end

    def test_scripts_extractor
      check = AssetSizeJavaScript.new
      scripts = check.scripts(<<~SOURCE)
        <html>
          <head>
            <script src="{{ '1.js' | asset_url }}" defer></script>
            <script src="{{ '2.js' | asset_url }}" async="async"></script>
            <script src="3.js" type="module"></script>
            <script type="text/javascript" src="4.js"></script>
          </head>
        </html>
      SOURCE

      expected = [
        "{{ '1.js' | asset_url }}",
        "{{ '2.js' | asset_url }}",
        "3.js",
        "4.js",
      ]

      assert_equal(expected, scripts.map(&:src))
    end

    def test_src_to_file_size
      theme = make_theme({
        "assets/theme.js" => "console.log('hello world'); console.log('Oh. Hi Mark!')",
      })

      assert_has_file_size("{{ 'theme.js' | asset_url }}", theme)
      RemoteAssetFile.any_instance.expects(:gzipped_size).times(3).returns(42)
      assert_has_file_size("https://example.com/foo.js", theme)
      assert_has_file_size("http://example.com/foo.js", theme)
      assert_has_file_size("//example.com/foo.js", theme)

      refute_has_file_size("{{ 'this_file_does_not_exist.js' | asset_url }}", theme)
      refute_has_file_size("{% if on_product %}https://hello.world{% else %}https://hi.world{% endif %}", theme)
    end

    def assert_has_file_size(src, theme)
      check = AssetSizeJavaScript.new
      check.theme = theme
      fs = check.src_to_file_size(src)
      assert(fs, "expected `#{src}` to have a file size.")
    end

    def refute_has_file_size(src, theme)
      check = AssetSizeJavaScript.new
      check.theme = theme
      fs = check.src_to_file_size(src)
      refute(fs, "didn't expect to get a file size for `#{src}`.")
    end

    def test_js_bundles_smaller_than_threshold
      offenses = analyze_theme(
        AssetSizeJavaScript.new(threshold_in_bytes: 10000000),
        {
          "assets/theme.js" => <<~JS,
            console.log('hello world');
          JS
          "templates/index.liquid" => <<~END,
            <html>
              <head>
                <script src="{{ 'theme.js' | asset_url }}" defer></script>
              </head>
            </html>
          END
        }
      )
      assert_offenses("", offenses)
    end

    def test_js_bundles_bigger_than_threshold
      offenses = analyze_theme(
        AssetSizeJavaScript.new(threshold_in_bytes: 2),
        "assets/theme.js" => <<~JS,
          console.log('hello world');
        JS
        "templates/index.liquid" => <<~END,
          <html>
            <head>
              <script src="{{ 'theme.js' | asset_url }}" defer></script>
            </head>
          </html>
        END
      )
      assert_offenses(<<~END, offenses)
        JavaScript on every page load exceding compressed size threshold (2 Bytes), consider using the import on interaction pattern. at templates/index.liquid:3
      END
    end
  end
end
