# frozen_string_literal: true

require "test_helper"

class DeprecatedFilterTest < Minitest::Test
  def test_reports_on_deprecate_filter
    offenses = analyze_theme(
      PlatformosCheck::DeprecatedFilter.new,
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
      PlatformosCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        color: {{ '#7ab55c' | color_to_rgb }};
      END
    )
    assert_offenses("", offenses)
  end

  def test_fixes_img_url
    sources = fix_theme(
      PlatformosCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        {{ product.featured_image | img_url: '200x', scale: 2, crop: 'center' }}
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
        {{ product.featured_image | img_url: variable }}
        {{ product.featured_image | img_url: '200x', scale: variable }}
      END
    )
    expected_sources = {
      "templates/index.liquid" => <<~LIQUID,
        {{ product.featured_image | image_url: width: 400, crop: 'center' }}
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
        {{ product.featured_image | img_url: variable }}
        {{ product.featured_image | img_url: '200x', scale: variable }}
      LIQUID
    }
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_fixes_img_url_named_sizes
    named_sizes = [
      ["pico", 16],
      ["icon", 32],
      ["thumb", 50],
      ["small", 100],
      ["compact", 160],
      ["medium", 240],
      ["large", 480],
      ["grande", 600],
      ["original", 1024],
    ]
    named_sizes.each do |(name, size)|
      sources = fix_theme(
        PlatformosCheck::DeprecatedFilter.new,
        "templates/index.liquid" => <<~END,
          {{ product.featured_image | img_url: '#{name}', scale: 2, crop: 'center' }}
          {{ product.featured_image | img_url: '#{name}', scale: 2 }}
          {{ product.featured_image | img_url: '#{name}' }}
        END
      )
      expected_sources = {
        "templates/index.liquid" => <<~LIQUID,
          {{ product.featured_image | image_url: width: #{size * 2}, height: #{size * 2}, crop: 'center' }}
          {{ product.featured_image | image_url: width: #{size * 2}, height: #{size * 2} }}
          {{ product.featured_image | image_url: width: #{size}, height: #{size} }}
        LIQUID
      }
      sources.each do |path, source|
        assert_equal(expected_sources[path], source, name)
      end
    end
  end

  def test_fixes_img_url_master
    sources = fix_theme(
      PlatformosCheck::DeprecatedFilter.new,
      "templates/index.liquid" => <<~END,
        {{ product.featured_image | img_url: 'master', scale: 2, crop: 'center' }}
        {{ product.featured_image | img_url: 'master', scale: 2 }}
        {{ product.featured_image | img_url: 'master' }}
      END
    )
    expected_sources = {
      "templates/index.liquid" => <<~LIQUID,
        {{ product.featured_image | image_url: crop: 'center' }}
        {{ product.featured_image | image_url }}
        {{ product.featured_image | image_url }}
      LIQUID
    }
    sources.each do |path, source|
      assert_equal(expected_sources[path], source, name)
    end
  end
end
