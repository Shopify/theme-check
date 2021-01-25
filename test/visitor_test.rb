# frozen_string_literal: true
require "test_helper"

class VisitorTest < Minitest::Test
  class TracerCheck < ThemeCheck::Check
    attr_reader :calls

    def initialize
      @calls = []
    end

    def respond_to?(method)
      method.start_with?("on_") || method.start_with?("after_") || super
    end

    def method_missing(method, node)
      @calls << method
      @calls << node.value if node.literal?
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def on_node(node)
      # Ignore, too noisy
    end

    def after_node(node)
      # Ignore, too noisy
    end
  end

  def setup
    @tracer = TracerCheck.new
    @visitor = ThemeCheck::Visitor.new(ThemeCheck::Checks.new([@tracer]))
  end

  def test_assign
    template = parse_liquid(<<~END)
      {% assign x = 'hello' %}
    END
    @visitor.visit_template(template)
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
    template = parse_liquid(<<~END)
      {% if x == 'condition' %}
        {% assign x = 'hello' %}
      {% else %}
      {% endif %}
    END
    @visitor.visit_template(template)
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
    template = parse_liquid(<<~END)
      {% schema %}
        { "muffin": true }
      {% endschema %}
    END
    @visitor.visit_template(template)
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
    template = parse_liquid(<<~END)
      {% paginate products by x %}
        {{ product.name }}
      {% endpaginate %}
    END
    @visitor.visit_template(template)
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

  def test_form
    template = parse_liquid(<<~END)
      {% form 'type', object, key: value %}
      {% endform %}
    END
    @visitor.visit_template(template)
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

  def test_theme_check_ignore_all_checks
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable{% endcomment %}
      hello
    END
    @visitor.visit_template(template)
    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\nhello\n",
      :after_document
    ], @tracer.calls)
  end

  def test_theme_check_ignore_certain_checks_including_tracer
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerCheck{% endcomment %}
    END
    @visitor.visit_template(template)
    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_theme_check_ignore_certain_checks_excluding_tracer
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable SomeOtherCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable SomeOtherCheck{% endcomment %}
    END
    @visitor.visit_template(template)
    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\n",
      :on_tag,
      :on_assign,
      :on_variable,
      :on_string, "hello",
      :after_variable,
      :after_assign,
      :after_tag,
      :on_string, "\n",
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end

  def test_theme_check_ignore_multiple_checks_including_tracer
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerCheck, SomeOtherCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerCheck, SomeOtherCheck{% endcomment %}
    END
    @visitor.visit_template(template)
    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer.calls)
  end
end
