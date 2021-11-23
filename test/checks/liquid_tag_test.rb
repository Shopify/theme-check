# frozen_string_literal: true
require "test_helper"

class LiquidTagTest < Minitest::Test
  def test_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
      END
    )
    assert_offenses(<<~END, offenses)
      Use {% liquid ... %} to write multiple tags at templates/index.liquid:1
    END
  end

  def test_ignores_non_consecutive_statements
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_ignores_inside_liquid_tag
    offenses = analyze_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% liquid
          assign x = 1
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
        %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_corrects_consecutive_statements
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% liquid
          if collection.image.size != 0
            assign collection_image = collection.image
          elsif collection.products.first.size != 0 and collection.products.first.media != empty
            assign collection_image = collection.products.first.featured_media.preview_image
          else
            assign collection_image = nil
          endif
        %}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% if collection.image.size != 0 %}
          {% assign collection_image = collection.image %}
        {% elsif collection.products.first.size != 0 and collection.products.first.media != empty %}
          {% assign collection_image = collection.products.first.featured_media.preview_image %}
        {% else %}
          {% assign collection_image = nil %}
        {% endif %}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_corrects_with_non_consecutive_statements_before
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        Hello
        {% liquid
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
          assign y = 2
          assign z = 3
        %}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
        Hello
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
        {% assign y = 2 %}
        {% assign z = 3 %}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_corrects_with_non_consecutive_statements_after
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% liquid
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
          assign x = 1
          assign y = 2
          assign z = 3
        %}
        Hello
        {% assign x = 1 %}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
        {% assign x = 1 %}
        {% assign y = 2 %}
        {% assign z = 3 %}
        Hello
        {% assign x = 1 %}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_corrects_multiple_blocks
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% liquid
          assign a = 1
          assign b = 2
          assign c = 3
          assign x = 1
          assign y = 2
        %}
        <p>Not</p>
        <p>a</p>
        <p>Liquid</p>
        <p>Tag</p>
        {% liquid
          assign a = 1
          assign b = 2
          assign c = 3
          assign x = 1
          assign y = 2
          assign z = 3
        %}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {% assign b = 2 %}
        {% assign c = 3 %}
        {% assign x = 1 %}
        {% assign y = 2 %}
        <p>Not</p>
        <p>a</p>
        <p>Liquid</p>
        <p>Tag</p>
        {% assign a = 1 %}
        {% assign b = 2 %}
        {% assign c = 3 %}
        {% assign x = 1 %}
        {% assign y = 2 %}
        {% assign z = 3 %}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_corrects_multiple_ifs
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% liquid
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
          assign x = 1
        %}
        <p>Not</p>
        <p>a</p>
        <p>Liquid</p>
        <p>Tag</p>
        {% liquid
          if x == 1
            assign y = 2
          else
            assign z = 2
          endif
          assign x = 1
        %}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
        {% assign x = 1 %}
        <p>Not</p>
        <p>a</p>
        <p>Liquid</p>
        <p>Tag</p>
        {% if x == 1 %}
          {% assign y = 2 %}
        {% else %}
          {% assign z = 2 %}
        {% endif %}
        {% assign x = 1 %}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end


  def test_corrects_with_whitespace_trimmed
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {%- liquid
          assign x = 1
          assign y = 2
          assign z = 3
          assign m = 1
        -%}
      END
    }

    sources = fix_theme(
      ThemeCheck::LiquidTag.new(min_consecutive_statements: 4),
      "templates/index.liquid" => <<~END,
        {%- assign x = 1 -%}
        {%- assign y = 2 -%}
        {%- assign z = 3 -%}
        {%- assign m = 1 -%}
      END
    )

    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
