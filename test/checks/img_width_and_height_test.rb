# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class ImgWidthAndHeightTest < Minitest::Test
    def test_no_offense_for_good_behaviour
      offenses = analyze_theme(
        ImgWidthAndHeight.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg" width="100" height="200">
          <img src="a.jpg" width="{{ image.width }}" height="{{ image.height }}">
          <img class="product__image lazyload"
              alt="{{ image.alt | escape }}"
              style="max-width: {{ 600 | times: image.aspect_ratio | round }}px; max-height: 600px;"
              src="{{ image.src }}"
              srcset="{% for width in responsive_image_widths %}
                {% assign img_width = width | append: 'x' %}
                {% if image.width >= width %}{{ image.src | img_url: img_width }} {{ width }}w,{% endif %}
              {% endfor %}"
              width="{{ image.width }}"
              height="{{ image.height }}"
              sizes="{{ 600 | times: image.aspect_ratio | round}}px"
            >
        END
      )
      assert_offenses("", offenses)
    end

    def test_doesnt_hang_on_self_closing_tag
      offenses = analyze_theme(
        ImgWidthAndHeight.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg" width="100" height="200"/>
          <img src="a.jpg" width="100" height="200" />
          <img src="a.jpg" width="{{ image.width }}" height="{{ image.height }}" />
          <img class="product__image lazyload"
              alt="{{ image.alt | escape }}"
              style="max-width: {{ 600 | times: image.aspect_ratio | round }}px; max-height: 600px;"
              src="{{ image.src }}"
              srcset="{% for width in responsive_image_widths %}
                {% assign img_width = width | append: 'x' %}
                {% if image.width >= width %}{{ image.src | img_url: img_width }} {{ width }}w,{% endif %}
              {% endfor %}"
              width="{{ image.width }}"
              height="{{ image.height }}"
              sizes="{{ 600 | times: image.aspect_ratio | round}}px"
            />
        END
      )
      assert_offenses("", offenses)
    end

    def test_ignore_lazysizes
      offenses = analyze_theme(
        ImgWidthAndHeight.new,
        "templates/index.liquid" => <<~END,
          <img data-src="a.jpg" data-sizes="auto">
          <img data-src="a_{width}.jpg" data-sizes="auto" data-widths="[100, 200, 500]">
        END
      )
      assert_offenses("", offenses)
    end

    def test_missing_width_and_height
      offenses = analyze_theme(
        ImgWidthAndHeight.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg">
          <img src="b.jpg" height="100">
          <img src="c.jpg" width="100">
          <img class="product__image lazyload"
              alt="{{ image.alt | escape }}"
              style="max-width: {{ 600 | times: image.aspect_ratio | round }}px; max-height: 600px;"
              src="{{ image.src }}"
              srcset="{% for width in responsive_image_widths %}
                {% assign img_width = width | append: 'x' %}
                {% if image.width >= width %}{{ image.src | img_url: img_width }} {{ width }}w,{% endif %}
              {% endfor %}"
              sizes="{{ 600 | times: image.aspect_ratio | round}}px"
            >
        END
      )
      assert_offenses(<<~END, offenses)
        Missing width and height attributes at templates/index.liquid:1
        Missing width attribute at templates/index.liquid:2
        Missing height attribute at templates/index.liquid:3
        Missing width and height attributes at templates/index.liquid:4
      END
    end

    def test_units_in_img_width_or_height
      offenses = analyze_theme(
        ImgWidthAndHeight.new,
        "templates/index.liquid" => <<~END,
          <img src="d.jpg" width="100px" height="200px">
          <img src="e.jpg" width="{{ image.width }}px" height="{{ image.height }}px">
        END
      )
      assert_offenses(<<~END, offenses)
        The width attribute does not take units. Replace with "100" at templates/index.liquid:1
        The height attribute does not take units. Replace with "200" at templates/index.liquid:1
        The width attribute does not take units. Replace with "{{ image.width }}" at templates/index.liquid:2
        The height attribute does not take units. Replace with "{{ image.height }}" at templates/index.liquid:2
      END
    end
  end
end
