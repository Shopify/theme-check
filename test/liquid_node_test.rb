# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class LiquidNodeTest < Minitest::Test
    def test_markup
      root = root_node(<<~END)
        <ul class="{% if true %}list{% endif %}>
          <li>{% liquid
            assign x = product | foo
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
          {{ 'x' }}
          {{
            'x'
          }}
          {%
            # inline comment
            # block
          %}
        </ul>
      END
      assert_can_find_node_with_markup(root, "if true ")
      assert_can_find_node_with_markup(root, "assign x = product | foo")
      assert_can_find_node_with_markup(root, "product | foo") # the Variable in the assign
      assert_can_find_node_with_markup(root, "echo x")
      assert_can_find_node_with_markup(root, "render\n    'foo'\n  ")
      assert_can_find_node_with_markup(root, "comment   ")
      assert_can_find_node_with_markup(root, "style\n  ")
      assert_can_find_node_with_markup(root, "style")
      assert_can_find_node_with_markup(root, "if\n  true")
      assert_can_find_node_with_markup(root, " 'x' ")
      assert_can_find_node_with_markup(root, "\n    'x'\n  ")
      assert_can_find_node_with_markup(root, "# inline comment\n    # block\n  ")
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
      assert_equal(12, node.inner_markup_start_index)
      assert_equal(205, node.inner_markup_end_index)
    end

    def test_block_start_and_end_comment
      comment = root_node(<<~END)
        {% comment %}hello world{% endcomment %}
      END
      node = find(comment) { |n| n.type_name == :comment }

      assert_equal(13, node.inner_markup_start_index)
      assert_equal(24, node.inner_markup_end_index)
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

      assert_equal(89, node.inner_markup_start_index)
      assert_equal(262, node.inner_markup_end_index)
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

      assert_equal(39, node.inner_markup_start_index)
      assert_equal(136, node.inner_markup_end_index)
    end

    def test_block_start_and_end_capture
      capture = root_node(<<~END)
        {% capture about_me %}
          I am {{ age }} and my favorite food is {{ favorite_food }}.
        {% endcapture %}
      END

      node = find(capture) { |n| n.type_name == :capture }

      assert_equal(22, node.inner_markup_start_index)
      assert_equal(85, node.inner_markup_end_index)
    end

    def test_block_end_index_variable
      [" x ", "y  ", "yyy"].each do |markup|
        root = root_node(<<~LIQUID)
          {{#{markup}}}
        LIQUID
        node = find(root) { |x| x.markup == markup }
        assert_equal(7, node.block_end_start_index)
        assert_equal(7, node.block_end_end_index)
      end
    end

    def test_block_end_index_liquid_tag
      ["assign x = 1"].each do |markup|
        liquid = <<~LIQUID
          {% liquid
            #{markup}
          %}
        LIQUID
        root = root_node(liquid)
        node = find(root) { |x| x.markup == markup }
        # The + 1 is for the "\n"
        assert_equal(liquid.match(markup).end(0) + 1, node.block_end_start_index)
        assert_equal(liquid.match(markup).end(0) + 1, node.block_end_end_index)
      end
    end

    def test_block_end_index_tag
      ["assign x = 1", "assign y = 1 ", "assign y = 1 \n"].each do |markup|
        liquid = <<~LIQUID
          {%#{markup}%}
        LIQUID
        root = root_node(liquid)
        node = find(root) { |x| x.markup == markup }
        assert_equal(liquid.match('%}').end(0), node.block_end_start_index)
        assert_equal(liquid.match('%}').end(0), node.block_end_end_index)
      end
    end

    BlockEndIndexTestCase = Struct.new(:type_name, :liquid, :block_end)

    def test_block_end_index_block_tag
      test_cases = [
        BlockEndIndexTestCase.new(:if, <<~LIQUID, /^{%- endif -%}$/),
          {% if nested %}
            {% if deep %}
              gotcha
            {%- endif -%}
          {% else %}
            contents
          {%- endif -%}
        LIQUID
        BlockEndIndexTestCase.new(:case, <<~LIQUID, "{%- endcase %}"),
          {% case thing %}
          {% when aaa %}
            scream
          {% else %}
            silence
          {%- endcase %}
        LIQUID
        BlockEndIndexTestCase.new(:for, <<~LIQUID, "{% endfor -%}"),
          {% for x in y %}
            do stuff
          {%- else %}
            contents
          {% endfor -%}
        LIQUID
      ]
      test_cases.each do |t|
        root = root_node(t.liquid)
        node = find(root) { |x| x.type_name == t.type_name }
        assert_equal(t.liquid.match(t.block_end).begin(0), node.block_end_start_index)
        assert_equal(t.liquid.match(t.block_end).end(0), node.block_end_end_index)
      end
    end

    def test_block_end_index_liquid_block_tag
      test_cases = [
        BlockEndIndexTestCase.new(:if, <<~LIQUID, /^  endif\n/),
          {% liquid
            if nested
              if deep
                echo gotcha
              endif
            else
              echo contents
            endif
          %}
        LIQUID
        BlockEndIndexTestCase.new(:case, <<~LIQUID, /^  endcase\n/),
          {%- liquid
            case thing
            when aaa
              echo scream
            else
              echo silence
            endcase
          %}
        LIQUID
        BlockEndIndexTestCase.new(:for, <<~LIQUID, /^  endfor\n/),
          {% liquid
            for thing in things
              echo scream
            else
              echo silence
            endfor
          -%}
        LIQUID
      ]
      test_cases.each do |t|
        root = root_node(t.liquid)
        node = find(root) { |x| x.type_name == t.type_name }
        assert_equal(t.liquid.match(t.block_end).begin(0), node.block_end_start_index)
        assert_equal(t.liquid.match(t.block_end).end(0), node.block_end_end_index)
      end
    end

    def test_block_start_and_end_for
      liquid = <<~END
        {% for product in collection.products %}
        The collection is not empty.
        {% else %}
        The collection is empty.
        {% endfor %}
      END
      fo = root_node(liquid)
      node = find(fo) { |n| n.type_name == :for }
      assert_equal(<<~INNER, node.inner_markup)
        \nThe collection is not empty.
        {% else %}
        The collection is empty.
      INNER
      assert_equal(liquid.match(/\nThe collection is not empty/).begin(0), node.inner_markup_start_index)
      assert_equal(liquid.match(/is empty\.\n/).end(0), node.inner_markup_end_index)
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

      assert_equal(55, node.inner_markup_start_index)
      assert_equal(82, node.inner_markup_end_index)
    end

    def test_block_start_and_end_if
      root = root_node(<<~END)
        {% if product.title == 'Awesome Shoes' %}
          You are buying some awesome shoes!
        {% endif %}
      END

      node = find(root) { |n| n.type_name == :if }

      assert_equal(41, node.inner_markup_start_index)
      assert_equal(79, node.inner_markup_end_index)
    end

    def test_block_start_and_end_unless
      root = root_node(<<~END)
        {% unless product.title == 'Awesome Shoes' %}
          You are not buying awesome shoes.
        {% endunless %}
      END

      node = find(root) { |n| n.type_name == :unless }

      assert_equal(0, node.inner_markup_start_row)
      assert_equal(45, node.inner_markup_start_column)
      assert_equal(2, node.inner_markup_end_row)
      assert_equal(0, node.inner_markup_end_column)
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

      assert_equal(32, node.inner_markup_start_index)
      assert_equal(345, node.inner_markup_end_index)
    end

    def test_outer_markup
      assert_can_find_node_with_outer_markup("literal\n")
      assert_can_find_node_with_outer_markup('{{x}}')
      assert_can_find_node_with_outer_markup('{{-x-}}')
      assert_can_find_node_with_outer_markup('{{ x }}')
      assert_can_find_node_with_outer_markup('{%  assign x = 1 %}')
      assert_can_find_node_with_outer_markup('{%assign x = 1%}')
      assert_can_find_node_with_outer_markup("  assign y = 1\n", <<~LIQUID)
        {% liquid
          assign x = 1
          assign y = 1
        %}
      LIQUID
      assert_can_find_node_with_outer_markup("  assign y = 1 ", <<~LIQUID)
        {% liquid
          assign x = 1
          assign y = 1 %}
      LIQUID
      assert_can_find_node_with_outer_markup("  assign y = 1", <<~LIQUID)
        {% liquid
          assign x = 1
          assign y = 1-%}
      LIQUID
      assert_can_find_node_with_outer_markup(<<~LIQUID.rstrip)
        {% if true %}
          sayhi
        {% endif %}
      LIQUID
      assert_can_find_node_with_outer_markup(<<~LIQUID.rstrip)
        {%if true%}
          sayhi
        {%endif%}
      LIQUID
      assert_can_find_node_with_outer_markup(<<~OUTER_MARKUP.rstrip)
        {%if nested%}
          {% if deep %}
            saysup
          {% else %}
            sayhi
          {% endif %}
        {%endif%}
      OUTER_MARKUP
      assert_can_find_node_with_outer_markup(<<~OUTER_MARKUP.rstrip, <<~LIQUID)
        if liquid_nested
          echo hi
        endif
      OUTER_MARKUP
        {% liquid
        if liquid_nested
          echo hi
        endif%}
      LIQUID
      assert_can_find_node_with_outer_markup(<<~OUTER_MARKUP.rstrip)
        {% case shipping_method.title %}
          {%   when 'International Shipping' %}
            You're shipping internationally. Your order should arrive in 2–3 weeks.
          {% when 'Domestic Shipping' %}
            Your order should arrive in 3–4 days.
          {% when 'Local Pick-Up' %}
            Your order will be ready for pick-up tomorrow.
          {% else %}
            Thank you for your order!
        {% endcase %}
      OUTER_MARKUP
    end

    def test_outer_markup_repeated_comments
      liquid = <<~LIQUID
        {% comment %}theme-check-disable foo{% endcomment %}
        {% comment %}theme-check-disable bar{% endcomment %}
        {%comment%}
        {%endcomment%}
      LIQUID
      assert_can_find_node_with_outer_markup('{% comment %}theme-check-disable foo{% endcomment %}', liquid)
      assert_can_find_node_with_outer_markup(<<~COMMENT.rstrip, liquid)
        {%comment%}
        {%endcomment%}
      COMMENT
    end

    def test_outer_markup_repeated_comments_inline_comment
      liquid = <<~LIQUID
        {% # theme-check-disable foo %}
        {% # theme-check-disable bar %}
        {%# theme-check-disable baz%}
      LIQUID
      assert_can_find_node_with_outer_markup('{% # theme-check-disable foo %}', liquid)
      assert_can_find_node_with_outer_markup('{%# theme-check-disable baz%}', liquid)
    end

    def test_inner_markup
      assert_node_inner_markup_equals('', '{{x}}')
      assert_node_inner_markup_equals('', '{{ x }}')
      assert_node_inner_markup_equals('', '{%  assign x = 1 %}')
      assert_node_inner_markup_equals('', '{%assign x = 1%}')
      assert_node_inner_markup_equals('', "  assign x = 1\n", <<~LIQUID)
        {% liquid
          assign x = 1
          assign y = 1
        %}
      LIQUID
      assert_node_inner_markup_equals("\n  sayhi\n", <<~LIQUID.rstrip)
        {% if true %}
          sayhi
        {% endif %}
      LIQUID
      assert_node_inner_markup_equals("\n  sayhi\n", <<~LIQUID.rstrip)
        {%if true%}
          sayhi
        {%endif%}
      LIQUID
      assert_node_inner_markup_equals(<<~INNER_MARKUP, <<~OUTER_MARKUP.rstrip)
        \n{% if deep %}
          saysup
        {% else %}
          sayhi
        {% endif %}
      INNER_MARKUP
        {%if nested%}
        {% if deep %}
          saysup
        {% else %}
          sayhi
        {% endif %}
        {%endif%}
      OUTER_MARKUP

      assert_node_inner_markup_equals("  echo hi\n", <<~OUTER_MARKUP.rstrip, <<~SOURCE)
        if liquid_nested
          echo hi
        endif
      OUTER_MARKUP
        {% liquid
        if liquid_nested
          echo hi
        endif%}
      SOURCE

      assert_node_inner_markup_equals(<<~INNER_MARKUP, <<~OUTER_MARKUP.rstrip)
        \n{%   when 'International Shipping' %}
          You're shipping internationally. Your order should arrive in 2–3 weeks.
        {% when 'Domestic Shipping' %}
          Your order should arrive in 3–4 days.
        {% when 'Local Pick-Up' %}
          Your order will be ready for pick-up tomorrow.
        {% else %}
          Thank you for your order!
      INNER_MARKUP
        {% case shipping_method.title %}
        {%   when 'International Shipping' %}
          You're shipping internationally. Your order should arrive in 2–3 weeks.
        {% when 'Domestic Shipping' %}
          Your order should arrive in 3–4 days.
        {% when 'Local Pick-Up' %}
          Your order will be ready for pick-up tomorrow.
        {% else %}
          Thank you for your order!
        {% endcase %}
      OUTER_MARKUP

      assert_node_inner_markup_equals(<<~INNER_MARKUP, <<~OUTER_MARKUP.rstrip)
        \n{{ form_errors | default_errors }}
        <div class="name">
        <label for="name">Name</label>
        <input type="text" name="customer[author]" value="{{ form.author }}">
        </div>
      INNER_MARKUP
        {% form 'new_comment', article, id: "newID", class: "custom-class", data-example: "100"%}
        {{ form_errors | default_errors }}
        <div class="name">
        <label for="name">Name</label>
        <input type="text" name="customer[author]" value="{{ form.author }}">
        </div>
        {% endform %}
      OUTER_MARKUP

      assert_node_inner_markup_equals("hello world", <<~OUTER_MARKUP.rstrip)
        {% comment %}hello world{% endcomment %}
      OUTER_MARKUP

      assert_node_inner_markup_equals(<<~INNER_MARKUP, <<~OUTER_MARKUP.rstrip)
        \n{% for product in collection.products %}
          <!--show product details here -->
        {% endfor %}
      INNER_MARKUP
        {% paginate collection.products by 5 %}
        {% for product in collection.products %}
          <!--show product details here -->
        {% endfor %}
        {% endpaginate %}
      OUTER_MARKUP
    end

    private

    # @returns [LiquidNode]
    def root_node(code)
      theme_file = parse_liquid(code)
      LiquidNode.new(theme_file.root, nil, theme_file)
    end

    # @returns [LiquidNode]
    def find(node, &block)
      return node if block.call(node)
      return nil if node.children.nil? || node.children.empty?
      node.children
        .map { |n| find(n, &block) }
        .find { |n| !n.nil? }
    end

    def map(node, &block)
      [
        block.call(node),
        node.children
          .map { |n| map(n, &block) },
      ].reject(&:nil?)
    end

    def assert_can_find_node_with_markup(root, markup)
      assert(
        find(root) { |n| n.markup == markup },
        "Expected to find node with markup == `#{markup}`"
      )
    end

    def assert_can_find_node_with_outer_markup(outer_markup, source = nil)
      source = outer_markup if source.nil?
      root = root_node(source)
      assert(
        find(root) { |n| n.outer_markup == outer_markup },
        <<~ERRMSG,
          Expected to find node with outer_markup:
          ```
          #{outer_markup}
          ```
          In the following tree of outer_markup:
          #{pretty_print(map(root, &:outer_markup))}
        ERRMSG
      )
    end

    def assert_node_inner_markup_equals(expected, outer_markup, source = nil)
      source = outer_markup if source.nil?
      root = root_node(source)
      node = find(root) { |n| n.outer_markup == outer_markup && n.inner_markup != n.outer_markup }
      if expected != node&.inner_markup
        debug(root)
      end
      refute_nil(node)
      assert_equal(
        expected,
        node.inner_markup,
      )
    end

    def map_tree(node)
      map(node) do |n|
        {
          type: n.value.class,
          outer: n.outer_markup,
          inner: n.inner_markup,
          markup: n.markup,
        }
      end
    end

    def debug(node)
      tree = map_tree(node)
      puts pretty_print(tree)
      # binding.pry
    end
  end
end
