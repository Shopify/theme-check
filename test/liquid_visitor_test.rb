# frozen_string_literal: true
require "test_helper"

class LiquidVisitorTest < Minitest::Test
  def setup
    @tracer = TracerCheck.new
    @visitor = PlatformosCheck::LiquidVisitor.new(PlatformosCheck::Checks.new([@tracer]), PlatformosCheck::DisabledChecks.new)
  end

  def run
    # Liquid-C is disabled from the Analyzer, before the visitor is called
    PlatformosCheck.with_liquid_c_disabled { super }
  end

  def test_assign
    theme_file = parse_liquid(<<~END)
      {% assign x = 'hello' %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_assign,
      :on_variable,
      :on_string, "hello",
      :after_variable,
      :after_assign,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_if
    theme_file = parse_liquid(<<~END)
      {% if x == 'condition' %}
        {% assign x = 'hello' %}
      {% else %}
      {% endif %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_if,
      :on_condition,
      :on_variable_lookup,
      :after_variable_lookup,
      :on_string, "condition",
      :on_block_body,
      :on_tag,
      :on_assign,
      :on_variable,
      :on_string, "hello",
      :after_variable,
      :after_assign,
      :after_tag,
      :after_block_body,
      :after_condition,
      :on_else_condition,
      :on_block_body,
      :after_block_body,
      :after_else_condition,
      :after_if,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_schema
    theme_file = parse_liquid(<<~END)
      {% schema %}
        { "muffin": true }
      {% endschema %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_schema,
      :on_string, "\n  { \"muffin\": true }\n",
      :after_schema,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_paginate
    theme_file = parse_liquid(<<~END)
      {% paginate products by x %}
        {{ product.name }}
      {% endpaginate %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_paginate,
      :on_string, "\n  ",
      :on_variable,
      :on_variable_lookup,
      :on_string, "name",
      :after_variable_lookup,
      :after_variable,
      :on_string, "\n",
      :on_variable_lookup,
      :after_variable_lookup,
      :after_paginate,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_render
    theme_file = parse_liquid(<<~END)
      {% for block in section.blocks %}
        {% assign x = 1 %}
        {% render block with x %}
      {% endfor %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_for,
      :on_block_body,
      :on_string,
      "\n" + "  ",
      :on_tag,
      :on_assign,
      :on_variable,
      :on_integer,
      1,
      :after_variable,
      :after_assign,
      :after_tag,
      :on_string,
      "\n" + "  ",
      :on_tag,
      :on_render,
      :on_variable_lookup,
      :after_variable_lookup,
      :on_variable_lookup,
      :after_variable_lookup,
      :after_render,
      :after_tag,
      :on_string,
      "\n",
      :after_block_body,
      :on_variable_lookup,
      :on_string,
      "blocks",
      :after_variable_lookup,
      :after_for,
      :after_tag,
      :on_string,
      "\n",
      :after_document,
    ], @tracer.calls)
  end

  def test_form
    theme_file = parse_liquid(<<~END)
      {% form 'type', object, key: value %}
      {% endform %}
    END
    @visitor.visit_liquid_file(theme_file)
    assert_equal([
      :on_document,
      :on_tag,
      :on_form,
      :on_string, "\n",
      :on_string, "type",
      :on_variable_lookup,
      :after_variable_lookup,
      :on_string, "key",
      :on_variable_lookup,
      :after_variable_lookup,
      :after_form,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end
end
