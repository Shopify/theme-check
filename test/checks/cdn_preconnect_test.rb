# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class CdnPreconnectTest < Minitest::Test
    def test_no_offense_with_other_external_domains
      offenses = analyze_theme(
        CdnPreconnect.new,
        "templates/index.liquid" => <<~END,
          <link rel="preconnect" href="https://example.com/">
          <link rel="preconnect" href="https://example.com/" crossorigin>
        END
      )
      assert_offenses("", offenses)
    end

    def test_no_offense_with_other_links
      offenses = analyze_theme(
        CdnPreconnect.new,
        "templates/index.liquid" => <<~END,
          <link rel="preload" href="https://example.com/foo.css" as="style">
          <link rel="stylesheet" href="https://example.com/bar.css">
          <link rel="icon">
        END
      )
      assert_offenses("", offenses)
    end

    def test_reports_preconnect_to_shopify_cdn
      offenses = analyze_theme(
        CdnPreconnect.new,
        "templates/index.liquid" => <<~END,
          <link rel="preconnect" href="https://cdn.shopify.com/">
        END
      )
      assert_offenses(<<~END, offenses)
        Preconnecting to cdn.shopify.com is unnecessary and can lead to worse performance at templates/index.liquid:1
      END
    end

    def test_reports_crossorigin_preconnect_to_shopify_cdn
      offenses = analyze_theme(
        CdnPreconnect.new,
        "templates/index.liquid" => <<~END,
          <link rel="preconnect" href="https://cdn.shopify.com/" crossorigin>
        END
      )
      assert_offenses(<<~END, offenses)
        Preconnecting to cdn.shopify.com is unnecessary and can lead to worse performance at templates/index.liquid:1
      END
    end
  end
end
