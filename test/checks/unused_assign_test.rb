# frozen_string_literal: true
require "test_helper"

class UnusedAssignTest < Minitest::Test
  def test_reports_unused_assigns
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      `x` is never used at templates/index.liquid:1
    END
  end

  def test_do_not_report_used_assigns
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {{ a }}
        {% assign b = 1 %}
        {{ 'a' | t: b }}
        {% assign c = 1 %}
        {{ 'a' | t: tags: c }}
        {% assign d = 1 %}
        {% render 'foo' with d %}
        {% assign e = "01234" | split: "" %}
        {% render 'foo' for e as item %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_do_not_report_used_assigns_bracket_syntax
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% liquid
          assign resource = request.page_type
          assign meta_value = [resource].metafields.namespace.key
          echo meta_value
        %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_do_not_report_assigns_used_before_defined
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% unless a %}
          {% assign a = 1 %}
        {% endunless %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_do_not_report_assigns_used_in_includes
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {% include 'using' %}
      END
      "snippets/using.liquid" => <<~END,
        {{ a }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_recursion_in_includes
    offenses = analyze_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign a = 1 %}
        {% include 'one' %}
      END
      "snippets/one.liquid" => <<~END,
        {% include 'two' %}
        {{ a }}
      END
      "snippets/two.liquid" => <<~END,
        {% if some_end_condition %}
          {% include 'one' %}
        {% endif %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_removes_unused_assign
    expected_sources = {
      "templates/index.liquid" => "\n",
    }
    sources = fix_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_removes_unused_assign_liquid_block
    expected_sources = {
      "templates/index.liquid" => <<~END,
        {% liquid
          assign x = 1
          assign y = 2
        %}
        {{ x }}
        {{ y }}
      END
    }
    sources = fix_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        {% liquid
          assign x = 1
          assign y = 2
          assign z = 3
        %}
        {{ x }}
        {{ y }}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_removes_unused_assign_middle_of_line
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>test case</p><p>test case</p>
      END
    }
    sources = fix_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        <p>test case</p>{% assign x = 1 %}<p>test case</p>
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end

  def test_removes_unused_assign_leaves_html
    expected_sources = {
      "templates/index.liquid" => <<~END,
        <p>test case</p>
      END
    }
    sources = fix_theme(
      PlatformosCheck::UnusedAssign.new,
      "templates/index.liquid" => <<~END,
        <p>test case</p>{% assign x = 1 %}
      END
    )
    sources.each do |path, source|
      assert_equal(expected_sources[path], source)
    end
  end
end
