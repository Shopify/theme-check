# frozen_string_literal: true
require "test_helper"

class DeprecatedFilterTest < Minitest::Test
  def test_reports_on_deprecate_filter
    offenses = analyze_theme(
      ThemeCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        color: {{ settings.color_name | hex_to_rgba: 0.5 }};
      END
    )
    assert_offenses(<<~END, offenses)
      Deprecated filter `hex_to_rgba`, consider using an alternative: `color_to_rgb`, `color_modify` at templates/index.liquid:1
    END
  end

  def test_does_not_report_on_filter
    offenses = analyze_theme(
      ThemeCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        color: {{ '#7ab55c' | color_to_rgb }};
      END
    )
    assert_offenses("", offenses)
  end

  def test_fixes_img_url
    sources = fix_theme(
      ThemeCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        {{ product.featured_image | img_url: '200x', scale: 2 }}
        {{ product.featured_image | img_url: '200x' }}
        {{ product.featured_image | img_url: '200x300' }}
        {{ product.featured_image | img_url: 'x300' }}
        {{ product.featured_image | img_url }}
        {{ product.featured_image
          | img_url: '200x'
        }}
        {{ product.featured_image
          | img_url: '200x',
            format: format
          | image_tag
        }}
        {{product.featured_image | img_url: '200x'}}
        {{-product.featured_image | img_url: '200x'-}}
        {% assign url = product.featured_image | img_url: '200x' %}
        {% assign url =
          product.featured_image | img_url: '200x'
        %}
        {{ product.featured_image | img_url: 'master' }}
        {{ product.featured_image | img_url: '4000x', scale: 2 }}

        // not supported:
        {{ product.featured_image | img_url: 'small' }}
        {{ product.featured_image | img_url: variable }}
        {{ product.featured_image | img_url: '200x', scale: variable }}
      END
    )
    expected_sources = {
      "templates/index.liquid" => <<~LIQUID,
        {{ product.featured_image | image_url: width: 400 }}
        {{ product.featured_image | image_url: width: 200 }}
        {{ product.featured_image | image_url: width: 200, height: 300 }}
        {{ product.featured_image | image_url: height: 300 }}
        {{ product.featured_image | image_url: width: 100, height: 100 }}
        {{ product.featured_image
          | image_url: width: 200
        }}
        {{ product.featured_image
          | image_url: width: 200, format: format
          | image_tag
        }}
        {{product.featured_image | image_url: width: 200}}
        {{-product.featured_image | image_url: width: 200-}}
        {% assign url = product.featured_image | image_url: width: 200 %}
        {% assign url =
          product.featured_image | image_url: width: 200
        %}
        {{ product.featured_image | image_url }}
        {{ product.featured_image | image_url: width: 5760 }}

        // not supported:
        {{ product.featured_image | img_url: 'small' }}
        {{ product.featured_image | img_url: variable }}
        {{ product.featured_image | img_url: '200x', scale: variable }}
      LIQUID
    }
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
