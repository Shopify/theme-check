# frozen_string_literal: true
require "test_helper"

class SpaceInsideBracesTest < Minitest::Test
  def test_reports_missing_space
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1%}
        {% assign x = 2-%}
        {%- assign x = 3%}
        {%- assign x = 4-%}
        {{ x}}
        {{ x-}}
        {{x }}
        {{-x }}
        {%comment%}{%-endcomment-%}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing before '%}' at templates/index.liquid:1
      Space missing before '-%}' at templates/index.liquid:2
      Space missing before '%}' at templates/index.liquid:3
      Space missing before '-%}' at templates/index.liquid:4
      Space missing before '}}' at templates/index.liquid:5
      Space missing before '-}}' at templates/index.liquid:6
      Space missing after '{{' at templates/index.liquid:7
      Space missing after '{{-' at templates/index.liquid:8
      Space missing after '{%' at templates/index.liquid:9
      Space missing after '{%-' at templates/index.liquid:9
      Space missing before '%}' at templates/index.liquid:9
      Space missing before '-%}' at templates/index.liquid:9
    END
  end

  def test_dont_report_when_no_missing_space
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% comment %}
        {% endcomment %}
        {%
          comment
        %}
        {% endcomment %}
        {%
          assign x = 'hi'
          | upcase
        %}
        {{
          color
          | color_to_hsl
          | remove: "hsl("
          | remove: ")"
        }}
        {{
          color |
          color_to_hsl |
          remove: "hsl(" |
          remove: ")"
        }}
      END
    )
    assert_offenses('', offenses)
  end

  def test_reports_extra_space
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{  x }}
        {{-  x }}
        {%  assign x = 1 %}
        {%-  assign x = 1 -%}
        {{ x  }}
        {{ x  -}}
        {% assign x = 1  %}
        {% assign x = 1  -%}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces after '{{' at templates/index.liquid:1
      Too many spaces after '{{-' at templates/index.liquid:2
      Too many spaces after '{%' at templates/index.liquid:3
      Too many spaces after '{%-' at templates/index.liquid:4
      Too many spaces before '}}' at templates/index.liquid:5
      Too many spaces before '-}}' at templates/index.liquid:6
      Too many spaces before '%}' at templates/index.liquid:7
      Too many spaces before '-%}' at templates/index.liquid:8
    END
  end

  def test_reports_extra_space_around_coma
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% form 'type',  object, key:value %}
        {% endform %}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing after ':' at templates/index.liquid:1
      Too many spaces after ',' at templates/index.liquid:1
    END
  end

  def test_reports_extra_space_around_pipeline
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ url  | asset_url | img_tag }}
        {{ url |  asset_url | img_tag }}
        {% assign my_upcase_string = "Hello world"  | upcase %}
        {% assign my_upcase_string = "Hello world" |  upcase %}
        {% echo "Hello world"  | upcase %}
        {% echo "Hello world" |  upcase %}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces before '|' at templates/index.liquid:1
      Too many spaces after '|' at templates/index.liquid:2
      Too many spaces before '|' at templates/index.liquid:3
      Too many spaces after '|' at templates/index.liquid:4
      Too many spaces before '|' at templates/index.liquid:5
      Too many spaces after '|' at templates/index.liquid:6
    END
  end

  def test_reports_missing_space_around_pipeline
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ url| asset_url | img_tag }}
        {{ url |asset_url | img_tag }}
        {% assign my_upcase_string = "Hello world"| upcase %}
        {% assign my_upcase_string = "Hello world" |upcase %}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing before '|' at templates/index.liquid:1
      Space missing after '|' at templates/index.liquid:2
      Space missing before '|' at templates/index.liquid:3
      Space missing after '|' at templates/index.liquid:4
    END
  end

  def test_dont_report_on_correct_spaces_around_pipeline
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ url | asset_url | img_tag }}
        {% assign my_upcase_string = "Hello world" | upcase %}
      END
    )
    assert_offenses('', offenses)
  end

  def test_reports_extra_space_after_colon_in_assign_tag
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% assign max_width = height | times:  image.aspect_ratio %}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces after ':' at templates/index.liquid:1
    END
  end

  def test_dont_report_on_proper_spaces_around_pipeline
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
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

  def test_corrects_missing_space
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {{ x }}
        {{ x }}
      END
    }
    sources = fix_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ x}}
        {{x }}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_corrects_extra_space
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {{ x }}
        {{ x }}
      END
    }
    sources = fix_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ x  }}
        {{  x }}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_reports_extra_space_after_operators
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {%- if x >  y -%}{%- endif -%}
        {%- if x <  y -%}{%- endif -%}
        {%- if x ==  "x" -%}{%- endif -%}
        {%- if x !=  "x" -%}{%- endif -%}
        {%- if x >=  y -%}{%- endif -%}
        {%- if x <=  y -%}{%- endif -%}
        {%- if x <>  y -%}{%- endif -%}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces after '>' at templates/index.liquid:1
      Too many spaces after '<' at templates/index.liquid:2
      Too many spaces after '==' at templates/index.liquid:3
      Too many spaces after '!=' at templates/index.liquid:4
      Too many spaces after '>=' at templates/index.liquid:5
      Too many spaces after '<=' at templates/index.liquid:6
      Too many spaces after '<>' at templates/index.liquid:7
    END
  end

  def test_reports_missing_space_after_operators
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {%- if x >y -%}{%- endif -%}
        {%- if x <y -%}{%- endif -%}
        {%- if x =="x" -%}{%- endif -%}
        {%- if x !="x" -%}{%- endif -%}
        {%- if x >=y -%}{%- endif -%}
        {%- if x <=y -%}{%- endif -%}
        {%- if x <>y -%}{%- endif -%}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing after '>' at templates/index.liquid:1
      Space missing after '<' at templates/index.liquid:2
      Space missing after '==' at templates/index.liquid:3
      Space missing after '!=' at templates/index.liquid:4
      Space missing after '>=' at templates/index.liquid:5
      Space missing after '<=' at templates/index.liquid:6
      Space missing after '<>' at templates/index.liquid:7
    END
  end

  def test_reports_extra_space_before_operators
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {%- if x  > y -%}{%- endif -%}
        {%- if x  < y -%}{%- endif -%}
        {%- if x  == "x" -%}{%- endif -%}
        {%- if x  != "x" -%}{%- endif -%}
        {%- if x  >= y -%}{%- endif -%}
        {%- if x  <= y -%}{%- endif -%}
        {%- if x  <> y -%}{%- endif -%}
      END
    )
    assert_offenses(<<~END, offenses)
      Too many spaces before '>' at templates/index.liquid:1
      Too many spaces before '<' at templates/index.liquid:2
      Too many spaces before '==' at templates/index.liquid:3
      Too many spaces before '!=' at templates/index.liquid:4
      Too many spaces before '>=' at templates/index.liquid:5
      Too many spaces before '<=' at templates/index.liquid:6
      Too many spaces before '<>' at templates/index.liquid:7
    END
  end

  def test_reports_missing_space_before_operators
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {%- if x> y -%}{%- endif -%}
        {%- if x< y -%}{%- endif -%}
        {%- if x== "x" -%}{%- endif -%}
        {%- if x!= "x" -%}{%- endif -%}
        {%- if x>= y -%}{%- endif -%}
        {%- if x<= y -%}{%- endif -%}
        {%- if x<> y -%}{%- endif -%}
      END
    )
    assert_offenses(<<~END, offenses)
      Space missing before '>' at templates/index.liquid:1
      Space missing before '<' at templates/index.liquid:2
      Space missing before '==' at templates/index.liquid:3
      Space missing before '!=' at templates/index.liquid:4
      Space missing before '>=' at templates/index.liquid:5
      Space missing before '<=' at templates/index.liquid:6
      Space missing before '<>' at templates/index.liquid:7
    END
  end

  def test_dont_report_with_correct_spaces_around_operators
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {%- if x > y -%}{%- endif -%}
        {%- if x < y -%}{%- endif -%}
        {%- if x == "x" -%}{%- endif -%}
        {%- if x != "x" -%}{%- endif -%}
        {%- if x >= y -%}{%- endif -%}
        {%- if x <= y -%}{%- endif -%}
        {%- if x <> y -%}{%- endif -%}
      END
    )
    assert_offenses('', offenses)
  end

  def test_dont_report_missing_spaces_inside_strings
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{ filter.min_value.value | money_without_currency | replace: '.', '' | replace: ',', '.' }}
        {{ paginate | default_pagination:
          next: '<i class="icon icon--right-t"></i><span class="icon-fallback__text">Next Page</span>',
          previous: '<i class="icon icon--left-t"></i><span class="icon-fallback__text">Previous Page</span>'
        }}
        {%
          render: "my-card",
          classname: "h-full md:hidden",
          image: block.settings.mobile-image
        %}
      END
    )
    assert_offenses('', offenses)
  end

  def test_reports_correct_location_range
    [
      {
        #          The two lines below are there to help identify the index
        #          0000000000111111111122222222223333333333
        #          0123456789012345678901234567890123456789
        liquid: "{{all_products }}",
        expected: "Space missing after '{{' at templates/index.liquid:2:3",
      },
      {
        liquid: "{{   all_products }}",
        expected: "Too many spaces after '{{' at templates/index.liquid:2:5",
      },
      {
        liquid: "{{ all_products}}",
        expected: "Space missing before '}}' at templates/index.liquid:14:15",
      },
      {
        liquid: "{{ all_products   }}",
        expected: "Too many spaces before '}}' at templates/index.liquid:15:18",
      },
      {
        liquid: "{{ 'a' | replace: ', ',',' | split: ',' }}",
        expected: "Space missing after ',' at templates/index.liquid:22:23",
      },
      {
        liquid: "{% assign x = n-%}",
        expected: "Space missing before '-%}' at templates/index.liquid:14:15",
      },
      {
        liquid: "{% assign x = n  -%}",
        expected: "Too many spaces before '-%}' at templates/index.liquid:15:17",
      },
      {
        liquid: '{%- if x !=  "x" -%}{%- endif -%}',
        expected: "Too many spaces after '!=' at templates/index.liquid:11:13",
      },
      {
        liquid: '{%- if x  != "x" -%}{%- endif -%}',
        expected: "Too many spaces before '!=' at templates/index.liquid:8:10",
      },
      {
        liquid: '{%- if x !="x" -%}{%- endif -%}',
        expected: "Space missing after '!=' at templates/index.liquid:9:11",
      },
      {
        liquid: '{%- if x!= "x" -%}{%- endif -%}',
        expected: "Space missing before '!=' at templates/index.liquid:8:10",
      },
      {
        liquid: <<~LIQUID,
          {% comment %}theme-check-disable foo{% endcomment %}
          {%comment %}
          {% endcomment %}
        LIQUID
        expected: "Space missing after '{%' at templates/index.liquid:55:56",
      },
    ].each do |test_desc|
      offenses = analyze_theme(
        PlatformosCheck::SpaceInsideBraces.new,
        "templates/index.liquid" => test_desc[:liquid]
      )
      assert_offenses_with_range(
        test_desc[:expected],
        offenses
      )
    end
  end

  def test_reports_properly_at_end_tag
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {% assign x = n-%}
        00000000001111111
        01234567890123456
        The two lines above are there to help identify the index
      END
    )
    assert_offenses_with_range(
      "Space missing before '-%}' at templates/index.liquid:14:15",
      offenses
    )
  end

  def test_dont_report_empty_variables
    offenses = analyze_theme(
      PlatformosCheck::SpaceInsideBraces.new,
      "templates/index.liquid" => <<~END,
        {{}}
      END
    )
    assert_offenses('', offenses)
  end
end
