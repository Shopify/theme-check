# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class HtmlNodeTest < Minitest::Test
    def test_markup
      html = <<~HTML
        <div>
          {{ 'foo.js' | asset_url | stylesheet_tag }}
          <link rel="stylesheet" href="{{ "styles.css" | asset_url }}">
          <script src="abc.js" defer></script>
          <img
            data-boolean
            src="abc.js"
            loading="lazy"
            width=100
            height='
              {%- if image.height > 5 -%}
                50
              {%- else -%}
                100
              {%- endif -%}
            '
          ></img>
          <iframe
            {% if settings.lazy %}
              loading="lazy"
            {% else %}
              loading="eager"
            {% endif %}
          ></iframe>
          <!doctype>
          <custom-element></custom-element>
          <{% hoho %}></{% hoho %}>
        </div>
      HTML
      root = root_node(html)
      # traversing tree making sure nothing throws
      find(root) { |node| node.markup == false }
      assert_markup_equals('<div>', root, "div")
      assert_markup_equals('<link rel="stylesheet" href="{{ "styles.css" | asset_url }}">', root, "link")
      assert_markup_equals('<script src="abc.js" defer>', root, "script")
      assert_markup_equals(html[html.index('<img')...html.index('</img>')], root, "img")
      assert_markup_equals(html[html.index('<iframe')...html.index('</iframe>')], root, "iframe")
      assert_markup_equals(html[html.index('<custom-element>')...html.index('</custom-element>')], root, "custom-element")
    end

    def test_no_freaking_out_on_rogue_carriage_returns
      html = <<~HTML
        <div>
          {{ 'foo.js' | asset_url | stylesheet_tag }}
          <link rel="stylesheet" href="{{ "styles.css" | asset_url }}">
          rogue \r character
          <script src="{ 'foo.js' }" defer></script>
        </div>
      HTML
      root = root_node(html)
      # traversing tree making sure nothing throws
      find(root) { |node| node.markup == false }
    end

    def test_line_numbers
      html = <<~HTML
        <div>
          {{
            'foo.js' | asset_url | stylesheet_tag
          }}
          <link rel="stylesheet" href="{{ "styles.css" | asset_url }}">
          <script src="abc.js" defer></script>
        </div>
      HTML
      root = root_node(html)
      assert_line_number_equals(1, root, "div")
      assert_line_number_equals(5, root, "link")
      assert_line_number_equals(6, root, "script")
    end

    def test_positions
      html = <<~HTML
        <div>
          {{
            'foo.js' | asset_url | stylesheet_tag
          }}
          <img
            src="abc.js"
            loading="lazy"
            width=100
            height=
              {%- if image.height > 5 -%}
                50
              {%- else -%}
                100
              {%- endif -%}
            data-boolean
          >
          </img>
        </div>
      HTML
      root = root_node(html)
      node = find(root) { |n| n.name == "img" }
      assert_equal(4, node.start_row)
      assert_equal(2, node.start_column)
      assert_equal(15, node.end_row)
      assert_equal(3, node.end_column)
    end

    private

    def assert_line_number_equals(expected, root, name)
      node = find(root) { |n| n.name == name }
      refute_nil(node, "Expected to find node to test node.markup == '#{expected}'")
      assert_equal(expected, node.line_number)
    end

    def assert_markup_equals(expected, root, name)
      node = find(root) { |n| n.name == name }
      refute_nil(node, "Expected to find node to test node.markup == '#{expected}'")
      assert_equal(expected, node.markup)
    end

    def find(node, &block)
      return node if block.call(node)
      return nil if node.children.nil? || node.children.empty?
      node.children
        .map { |n| find(n, &block) }
        .find { |n| !n.nil? }
    end

    def root_node(code)
      liquid_file = parse_liquid(code)
      HtmlNode.parse(liquid_file)
    end
  end
end
