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

    def method_missing(method, *)
      @calls << method
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
      :on_string,
      :after_variable,
      :after_assign,
      :after_tag,
      :on_string,
      :after_document,
    ], @tracer.calls)
  end

  def test_if
    template = parse_liquid(<<~END)
      {% if x == 'hello' %}
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
      :on_string,
      :on_block_body,
      :on_tag,
      :on_assign,
      :on_variable,
      :on_string,
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
      :on_string,
      :after_document,
    ], @tracer.calls)
  end

  def test_schema
    template = parse_liquid(<<~END)
      {% schema %}
        {
          "muffin": true
        }
      {% endschema %}
    END
    @visitor.visit_template(template)
    assert_equal([
      :on_document,
      :on_tag,
      :on_schema,
      :on_string,
      :after_schema,
      :after_tag,
      :on_string,
      :after_document,
    ], @tracer.calls)
  end
end
