# frozen_string_literal: true
require "test_helper"

class AssetPreloadTest < Minitest::Test
  def test_no_offense_with_link_element
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="a.css" rel="stylesheet">
        <link href="b.com" rel="preconnect">
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_stylesheet_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="a.css" rel="preload" as="style">
      END
    )
    assert_offenses(<<~END, offenses)
      Prefer preload argument on stylesheet_tag filter at templates/index.liquid:1
    END
  end

  def test_reports_image_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="a.png" rel="preload" as="image">
      END
    )
    assert_offenses(<<~END, offenses)
      Prefer preload argument on image_tag filter at templates/index.liquid:1
    END
  end

  def test_reports_general_preloading
    offenses = analyze_theme(
      ThemeCheck::AssetPreload.new,
      "templates/index.liquid" => <<~END,
        <link href="a..js" rel="preload" as="script">
      END
    )
    assert_offenses(<<~END, offenses)
      Prefer preload_tag filter at templates/index.liquid:1
    END
  end
end
