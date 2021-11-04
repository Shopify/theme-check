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
          {%
            style
          %}
          {% endstyle %}
          {% style%}{% endstyle %}
          {% if
          true%}{% endif %}
        </ul>
      END
      assert_can_find_node_with_markup(root, "if true ")
      assert_can_find_node_with_markup(root, "assign x = 1")
      assert_can_find_node_with_markup(root, "echo x")
      assert_can_find_node_with_markup(root, "render\n    'foo'\n  ")
      assert_can_find_node_with_markup(root, "comment   ")
      assert_can_find_node_with_markup(root, "style\n  ")
      assert_can_find_node_with_markup(root, "style")
      assert_can_find_node_with_markup(root, "if\n  true")
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

    def test_block_start_and_end_schema
      schema = root_node(<<~END)
        {% schema %}
          {
            "name": {
              "en": "Hello",
              "fr": "Bonjour"
            },
            "settings": [
              {
                "id": "product",
                "label": {
                  "en": "Product"
                }
              }
            ]
          }
        {% endschema %}
      END

      node = find(schema) { |n| n.type_name == :schema }
      assert_equal(12, node.block_body_start_index)
      assert_equal(205, node.block_body_end_index)
    end

    def test_block_start_and_end_comment
      comment = root_node(<<~END)
        {% comment %}hello world{% endcomment %}
      END
      node = find(comment) { |n| n.type_name == :comment }

      assert_equal(13, node.block_body_start_index)
      assert_equal(24, node.block_body_end_index)
    end

    def test_block_start_and_end_form
      form = root_node(<<~END)
        {% form 'new_comment', article, id: "newID", class: "custom-class", data-example: "100"%}
          {{ form_errors | default_errors }}
          <div class="name">
          <label for="name">Name</label>
          <input type="text" name="customer[author]" value="{{ form.author }}">
          </div>
        {% endform %}
      END

      node = find(form) { |n| n.type_name == :form }

      assert_equal(89, node.block_body_start_index)
      assert_equal(262, node.block_body_end_index)
    end

    def test_block_start_and_end_paginate
      paginate = root_node(<<~END)
        {% paginate collection.products by 5 %}
          {% for product in collection.products %}
            <!--show product details here -->
          {% endfor %}
        {% endpaginate %}
      END

      node = find(paginate) { |n| n.type_name == :paginate }

      assert_equal(39, node.block_body_start_index)
      assert_equal(136, node.block_body_end_index)
    end

    def test_block_start_and_end_capture
      capture = root_node(<<~END)
        {% capture about_me %}
          I am {{ age }} and my favorite food is {{ favorite_food }}.
        {% endcapture %}
      END

      node = find(capture) { |n| n.type_name == :capture }

      assert_equal(22, node.block_body_start_index)
      assert_equal(85, node.block_body_end_index)
    end

    def test_block_start_and_end_for
      fo = root_node(<<~END)
        {% for product in collection.products %}
          {{ product.title }}
        {% else %}
          The collection is empty.
        {% endfor %}
      END

      node = find(fo) { |n| n.type_name == :for }
      assert_equal(40, node.block_body_start_index)
      assert_equal(101, node.block_body_end_index)
    end

    def test_block_start_and_end_tablerow
      tablerow = root_node(<<~END)
        <table>
          {% tablerow product in collection.products %}
            {{ product.title }}
          {% endtablerow %}
        </table>
      END

      node = find(tablerow) { |n| n.type_name == :table_row }

      assert_equal(55, node.block_body_start_index)
      assert_equal(82, node.block_body_end_index)
    end

    def test_block_start_and_end_if
      root = root_node(<<~END)
        {% if product.title == 'Awesome Shoes' %}
          You are buying some awesome shoes!
        {% endif %}
      END

      node = find(root) { |n| n.type_name == :if }

      assert_equal(41, node.block_body_start_index)
      assert_equal(79, node.block_body_end_index)
    end

    def test_block_start_and_end_unless
      root = root_node(<<~END)
        {% unless product.title == 'Awesome Shoes' %}
          You are not buying awesome shoes.
        {% endunless %}
      END

      node = find(root) { |n| n.type_name == :unless }

      assert_equal(45, node.block_body_start_index)
      assert_equal(82, node.block_body_end_index)
    end

    def test_block_start_and_end_case
      root = root_node(<<~END)
        {% case shipping_method.title %}
          {% when 'International Shipping' %}
            You're shipping internationally. Your order should arrive in 2–3 weeks.
          {% when 'Domestic Shipping' %}
            Your order should arrive in 3–4 days.
          {% when 'Local Pick-Up' %}
            Your order will be ready for pick-up tomorrow.
          {% else %}
            Thank you for your order!
        {% endcase %}
      END

      node = find(root) { |n| n.type_name == :case }

      assert_equal(32, node.block_body_start_index)
      assert_equal(345, node.block_body_end_index)
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

    def assert_can_find_node_with_markup(root, markup)
      assert(
        find(root) { |n| n.markup == markup },
        "Expected to find node with markup == `#{markup}`"
      )
    end
  end
end
