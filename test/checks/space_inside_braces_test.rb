# frozen_string_literal: true
require "test_helper"

class SpaceInsideBracesTest < Minitest::Test
  def test_reports_missing_space
    offenses = analyze_theme(
      ThemeCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1%}
        {{ x}}
        {{x }}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing before '%}' at templates/index.liquid:1
      Space missing before '}}' at templates/index.liquid:2
      Space missing after '{{' at templates/index.liquid:3
    END
  end

  def test_reports_extra_space
    offenses = analyze_theme(
      ThemeCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{  x }}
        {% assign x = 1  %}
        {{ x  }}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces after '{{' at templates/index.liquid:1
      Too many spaces before '%}' at templates/index.liquid:2
      Too many spaces before '}}' at templates/index.liquid:3
    END
  end

  def test_reports_extra_space_around_coma
    offenses = analyze_theme(
      ThemeCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% form 'type',  object, key:value %}
        {% endform %}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces after ',' at templates/index.liquid:1
      Space missing after ':' at templates/index.liquid:1
    END
  end

  def test_dont_report_with_proper_spaces
    offenses = analyze_theme(
      ThemeCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        {{ x }}
        {% form 'type', object, key: value, key2: value %}
        {% endform %}
        {{ "ignore:stuff,  indeed" }}
        {% render 'product-card',
          product_card_product: product_recommendation,
          show_vendor: section.settings.show_vendor,
          media_size: section.settings.product_recommendations_image_ratio,
          center_align_text: section.settings.center_align_text
        %}
            {% render 'product-card',
              product_card_product: product,
              show_vendor: section.settings.show_vendor,
              media_size: section.settings.product_image_ratio,
              center_align_text: section.settings.center_align_text,
              show_full_details: true
            %}
      END
    )
    assert_equal("", offenses.join("\n"))
  end
end
