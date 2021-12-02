# frozen_string_literal: true
require "test_helper"
require "minitest/focus"

class MissingEnableCommentTest < Minitest::Test
  def test_always_enabled_by_default
    refute(ThemeCheck::MissingEnableComment.new.can_disable?)
  end

  def test_no_default_noops
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
        {% comment %}theme-check-enable{% endcomment %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_first_line_comment_disables_entire_file
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_non_first_line_comment_triggers_offense
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      All checks were disabled but not re-enabled with theme-check-enable at templates/index.liquid
    END
  end

  def test_specific_checks_disabled
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      Minitest::Test::TracerCheck.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable TracerCheck{% endcomment %}
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      TracerCheck was disabled but not re-enabled with theme-check-enable at templates/index.liquid
    END
  end

  def test_specific_checks_disabled_and_reenabled
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      Minitest::Test::TracerCheck.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      TracerCheck, AnotherCheck were disabled but not re-enabled with theme-check-enable at templates/index.liquid
    END
  end

  def test_specific_checks_disabled_and_reenabled_with_all_checks_disabled
    offenses = analyze_theme(
      ThemeCheck::MissingEnableComment.new,
      Minitest::Test::TracerCheck.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
        {% assign x = 1 %}
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      All checks were disabled but not re-enabled with theme-check-enable at templates/index.liquid
    END
  end

  def test_adds_missing_enable_all
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
        {% comment %}theme-check-enable{% endcomment %}
      END
    }
    sources = fix_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_adds_missing_enable_specific_checks
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
        {% assign x = 1 %}
        {% comment %}theme-check-enable TracerCheck, AnotherCheck{% endcomment %}
      END
    }
    sources = fix_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
        {% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_adds_missing_enable_after_last_check_when_multiple_checks_disabled
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable OneCheck, TwoCheck{% endcomment %}
          {% assign x = 1 %}
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
          {% assign x = 1 %}
        {% comment %}theme-check-disable{% endcomment %}
          {% assign x = 1 %}
        {% comment %}theme-check-enable{% endcomment %}
      END
    }
    sources = fix_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable OneCheck, TwoCheck{% endcomment %}
          {% assign x = 1 %}
        {% comment %}theme-check-disable TracerCheck, AnotherCheck{% endcomment %}
          {% assign x = 1 %}
        {% comment %}theme-check-disable{% endcomment %}
          {% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_comment_insert_location
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
        {% comment %}theme-check-enable{% endcomment %}
        {% assign x = 1 %}
      END
    }
    sources = fix_theme(
      ThemeCheck::MissingEnableComment.new,
      "templates/index.liquid" => <<~END,
        <p>Hello, world</p>
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 1 %}
        {% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
