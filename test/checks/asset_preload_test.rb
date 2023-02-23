# frozen_string_literal: true
require "test_helper"

class AssetPreloadTest < Minitest::Test
  def test_no_offense_with_link_element
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="{{ 'a.css' | asset_url }}" rel="stylesheet">
        <link href="b.com" rel="preconnect">
      END
    )
    assert_offenses("", offenses)
  end

  def test_no_offense_for_font_preload
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link as="font" href="{{ setting.type_body_font | font_url }}" rel="preload">
      END
    )
    assert_offenses("", offenses)
  end

  def test_no_warning_for_external_assets
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link rel="preload" as="script" href="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js">
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_stylesheet_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="{{ 'a.css' | asset_url }}" rel="preload" as="style">
      END
    )
    assert_offenses(<<~END, offenses)
      For better performance, prefer using the preload argument of the stylesheet_tag filter at templates/index.liquid:1
    END
  end

  def test_reports_image_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="{{ 'a.png' | image_url }}" rel="preload" as="image">
      END
    )
    assert_offenses(<<~END, offenses)
      For better performance, prefer using the preload argument of the image_tag filter at templates/index.liquid:1
    END
  end

  def test_reports_general_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="{{ 'script.js' | asset_url  }}" rel="preload" as="script">
      END
    )
    assert_offenses(<<~END, offenses)
      For better performance, prefer using the preload_tag filter at templates/index.liquid:1
    END
  end
end
