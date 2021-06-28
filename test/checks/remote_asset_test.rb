# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class RemoteAssetTest < Minitest::Test
    def test_no_offense_for_good_behaviour
      offenses = analyze_theme(
        RemoteAsset.new,
        "templates/index.liquid" => <<~END,
          <!-- scripts -->
          <script src="{{ 'theme.js' | asset_url }}" defer></script>

          <!-- styles -->
          {{ 'theme.css' | asset_url | stylesheet_tag }}
          <link href="{{ 'theme.css' | asset_url }}" rel="stylesheet">
          <link rel="stylesheet" href="https://cdn.shopify.com/shopifycloud/ui.css">

          <!-- images -->
          <img alt="logo" src="{{ 'heart.png' | asset_url }}" width="100" height="100">
          <img alt="logo" src="{{ 'heart.png' | asset_url }}" width="100" height="100"/>
          <source src="{{ 'heart.png' | asset_url }}">

          <!-- Good kind of URLs -->
          <source src="foo.png">
          <source src="/app/src/foo.png">
          <source src="blob:...">
          <source src="data:image/png;base64,...">
          <source src="{{ image.src | img_url }}">
          <source src="{{ image | img_url }}">

          <!-- weird edge cases from the wild -->
          <img alt="logo" src="" data-src="{{ url | asset_url | img_tag }}" width="100" height="100" />
        END
      )
      assert_offenses("", offenses)
    end

    def test_no_offense_for_stuff_we_dont_care_about
      offenses = analyze_theme(
        RemoteAsset.new,
        "templates/index.liquid" => <<~END,
          <link href="https://dont.care" rel="preconnect">
        END
      )
      assert_offenses("", offenses)
    end

    def test_flag_use_of_scripts_to_remote_domains
      offenses = analyze_theme(
        RemoteAsset.new,
        "templates/index.liquid" => <<~END,
          <script src="https://example.com/jquery.js" defer></script>
        END
      )
      assert_offenses(<<~END, offenses)
        Asset should be served by the Shopify CDN for better performance. at templates/index.liquid:1
      END
    end

    def test_flag_use_of_remote_stylesheet
      offenses = analyze_theme(
        RemoteAsset.new,
        "templates/index.liquid" => <<~END,
          <link href="https://example.com/bootstrap.css" rel="stylesheet">
          <link href="{{ "https://example.com/bootstrap.css" | replace: 'bootstrap', 'tailwind' }}" rel="stylesheet">
        END
      )
      assert_offenses(<<~END, offenses)
        Asset should be served by the Shopify CDN for better performance. at templates/index.liquid:1
        Asset should be served by the Shopify CDN for better performance. at templates/index.liquid:2
      END
    end

    def test_flag_use_of_image_drops_without_img_url_filter
      offenses = analyze_theme(
        RemoteAsset.new,
        "templates/index.liquid" => <<~END,
          <img src="{{ image }}">
          <img src="{{ image.src }}">
        END
      )
      assert_offenses(<<~END, offenses)
        Asset should be served by the Shopify CDN for better performance. at templates/index.liquid:1
        Asset should be served by the Shopify CDN for better performance. at templates/index.liquid:2
      END
    end
  end
end
