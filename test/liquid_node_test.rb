# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class LiquidNodeTest < Minitest::Test
    def test_markup
      root = root_node(<<~END)
        <ul class="{% if true %}list{% endif %}>
          <li>{% liquid
            assign x = 1
            echo x
          %}</li>
          {%
            render
            'foo'
          %}
          {% comment   %}hi{% endcomment %}
        </ul>
      END
      node = find(root) { |n| n.type_name == :if }
      assert_equal("if true ", node.markup)
      node = find(root) { |n| n.type_name == :assign }
      assert_equal("assign x = 1", node.markup)
      node = find(root) { |n| n.type_name == :echo }
      assert_equal("echo x", node.markup)
      node = find(root) { |n| n.type_name == :render }
      assert_equal("render\n    'foo'\n  ", node.markup)
      # Note, the following also doesn't return content as expected.
      # We're getting "comment " back
      # node = find(root) { |n| n.type_name == :comment }
      # assert_equal("comment   ", node.markup)
    end

    def test_inside_liquid_tag?
      root = root_node(<<~END)
        <ul class="{% if true %}list{% endif %}>
          <li>{% liquid
            assign x = 1
            echo x
          %}</li>
          {%
            render
            'foo'
          %}
          <div class="form-vertical">{%form 'recover_customer_password'%}{%comment%}
            Add a hidden span to indicate the form was submitted succesfully.
          {%endcomment%}
          {%endform%}
          # weird implementation edge case (markup is present before tag on the same line)
          a {% if a %}{% endif %}
      END
      node = find(root) { |n| n.markup == "if true " }
      refute(node.inside_liquid_tag?)
      node = find(root) { |n| n.type_name == :assign }
      assert(node.inside_liquid_tag?)
      node = find(root) { |n| n.type_name == :echo }
      assert(node.inside_liquid_tag?)
      node = find(root) { |n| n.type_name == :render }
      refute(node.inside_liquid_tag?)
      node = find(root) { |n| n.type_name == :comment }
      refute(node.inside_liquid_tag?)
      node = find(root) { |n| n.markup =~ /if a/ }
      refute(node.inside_liquid_tag?)
    end

    def test_whitespace_trimmed_start?
      root = root_node(<<~END)
        {%- assign x = 1 %}
        {% assign x = 2 %}
        {%-
          assign x = 3
        %}
        {%
          assign x = 4
        %}
        pre text{%-
          assign x = 5
        %}
        pre text{%
          assign x = 6
        %}
        {% liquid
          assign x = 7
        %}
        {%- liquid
          assign x = 8
        -%}
        {{- yes }}
        {{ no }}
        {{-
          foo
        }}
        {{
          bar
        -}}
      END
      node = find(root) { |n| n.markup =~ /assign x = 1/ }
      assert(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 2/ }
      refute(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 3/ }
      assert(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 4/ }
      refute(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 5/ }
      assert(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 6/ }
      refute(node.whitespace_trimmed_start?)
      # doesn't make sense in liquid tags
      node = find(root) { |n| n.markup =~ /assign x = 7/ }
      refute(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /assign x = 8/ }
      refute(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /yes/ }
      assert(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /no/ }
      refute(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /foo/ }
      assert(node.whitespace_trimmed_start?)
      node = find(root) { |n| n.markup =~ /bar/ }
      refute(node.whitespace_trimmed_start?)
    end

    def test_whitespace_trimmed_end?
      root = root_node(<<~END)
        {% assign x = 1 -%}
        {% assign x = 2 %}
        {%
          assign x = 3
        -%}
        {%
          assign x = 4
        %}
        pre text{%
          assign x = 5
        -%}
        pre text{%
          assign x = 6
        %}
        {% liquid
          assign x = 7
        %}
        {%- liquid
          assign x = 8
        -%}
        {{ yes -}}
        {{ no }}
        {{-
          foo
        }}
        {{
          bar
        -}}
      END
      node = find(root) { |n| n.markup =~ /assign x = 1/ }
      assert(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 2/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 3/ }
      assert(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 4/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 5/ }
      assert(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 6/ }
      refute(node.whitespace_trimmed_end?)
      # doesn't make sense in liquid tags
      node = find(root) { |n| n.markup =~ /assign x = 7/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /assign x = 8/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /yes/ }
      assert(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /no/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /foo/ }
      refute(node.whitespace_trimmed_end?)
      node = find(root) { |n| n.markup =~ /bar/ }
      assert(node.whitespace_trimmed_end?)
    end

    private

    def root_node(code)
      theme_file = parse_liquid(code)
      LiquidNode.new(theme_file.root, nil, theme_file)
    end

    def find(node, &block)
      return node if block.call(node)
      return nil if node.children.nil? || node.children.empty?
      node.children
        .map { |n| find(n, &block) }
        .find { |n| !n.nil? }
    end
  end
end
