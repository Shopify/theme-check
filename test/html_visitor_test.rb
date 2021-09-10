# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class HtmlVisitorTest < Minitest::Test
    def setup
      @tracer = TracerCheck.new
      @visitor = HtmlVisitor.new(Checks.new([@tracer]))
    end

    def test_elements_with_variables
      template = parse_liquid(<<~END)
        <a href="/about">About</a>
        <img src="a.jpg" width="{{ image.width }}" height="{{ image.height }}">
      END
      @visitor.visit_template(template)
      assert_equal([
        :on_document,
        :on_element,
        :on_a,
        :on_text, "About",
        :after_a,
        :after_element,
        :on_text, "\n",
        :on_element,
        :on_img,
        :after_img,
        :after_element,
        :on_text, "\n",
        :after_document
      ], @tracer.calls)
    end

    def test_elements_with_liquid_tags
      template = parse_liquid(<<~END)
        {% capture x %}
          <a href="/about">About</a>
        {% endcapture %}
      END
      @visitor.visit_template(template)
      assert_equal([
        :on_document,
        :on_text, "{% capture x %}\n  ",
        :on_element,
        :on_a,
        :on_text, "About",
        :after_a,
        :after_element,
        :on_text, "\n{% endcapture %}\n",
        :after_document
      ], @tracer.calls)
    end

    def test_elements_with_quotes_inside_quotes
      @attribute_checker = HTMLAttributeIntegrityMockCheck.new
      @visitor = HtmlVisitor.new(Checks.new([@attribute_checker]))
      template = parse_liquid(<<~END)
        <script href="{{ "a.js" | asset_url }}" defer></script>
        <script href='{{ 'b.js' | asset_url }}' defer></script>
        <script href='{{ 'don\\'t you love quotes' | asset_url }}' defer></script>
        <script href='fun{{ 'hardcode+variable' | asset_url }}' defer></script>
        <script href='fun{%- if 'hardcode' -%}somemore{%- endif -%}' defer></script>
      END

      @visitor.visit_template(template)
      [
        {
          name: "script",
          attributes: {
            "href" => '{{ "a.js" | asset_url }}',
            "defer" => '',
          },
        },
        {
          name: "script",
          attributes: {
            "href" => "{{ 'b.js' | asset_url }}",
            "defer" => '',
          },
        },
        {
          name: "script",
          attributes: {
            # the escaped quote gets replaced but that's OK. HTML
            # doesn't handle escaped quotes in attributes so we just
            # have to make do. This means the asset_url will be wrong
            # if that happens.
            "href" => "{{ 'don\\'t you love quotes' | asset_url }}",
            "defer" => '',
          },
        },
        {
          name: "script",
          attributes: {
            "href" => "fun{{ 'hardcode+variable' | asset_url }}",
            "defer" => '',
          },
        },
        {
          name: "script",
          attributes: {
            "href" => "fun{%- if 'hardcode' -%}somemore{%- endif -%}",
            "defer" => '',
          },
        },
      ].each_with_index do |element, i|
        assert_equal(element, @attribute_checker.elements[i])
      end
    end

    def test_elements_with_greater_than_signs
      @attribute_checker = HTMLAttributeIntegrityMockCheck.new
      @visitor = HtmlVisitor.new(Checks.new([@attribute_checker]))
      template = parse_liquid(<<~END)
        <img
          srcset='{%- if image.width > 800 -%}{{ image | img_url: "800x" }} 800w, {%- endif -%}'
        >
      END

      @visitor.visit_template(template)
      [
        {
          name: "img",
          attributes: {
            "srcset" => '{%- if image.width > 800 -%}{{ image | img_url: "800x" }} 800w, {%- endif -%}',
          },
        },
      ].each_with_index do |element, i|
        assert_equal(element, @attribute_checker.elements[i])
      end
    end

    # Nokogiri would see the > character in the liquid
    # condition and end the img element there and consider what
    # follows as text. There's no good way of handling this but it
    # should at least close the HTML tag properly.
    def test_element_with_greater_than_sign_outside_of_attribute
      @attribute_checker = HTMLAttributeIntegrityMockCheck.new
      @visitor = HtmlVisitor.new(Checks.new([@attribute_checker]))
      template = parse_liquid(<<~END)
        <img
          {% if image.width > 800 %}width="800"{% endif %}
        >
      END

      @visitor.visit_template(template)
      [
        {
          name: "img",
          attributes: {
            "{% if image.width > 800 %}width" => "800",
            "{% endif %}" => "",
          },
        },
      ].each_with_index do |element, i|
        assert_equal(element, @attribute_checker.elements[i])
      end
    end

    def test_weird_edge_cases_shouldnt_throw
      @attribute_checker = HTMLAttributeIntegrityMockCheck.new
      @visitor = HtmlVisitor.new(Checks.new([@attribute_checker]))
      template = parse_liquid(<<~END)
        <html>
          <b x={% %} y="{{ }}" z="{{}}" a="{{}}" b="{{}}" c="{{}}" d="{{}}"></b>
          <b x={% %} y="{{ }}" z="{{}}" a="{{}}" b="{{}}" c="{{}}" d="{{}}"></b>
          <b x={% %} y="{{ }}" z="{{}}" a="{{}}" b="{{}}" c="{{}}" d="{{}}"></b>
        </html>
      END
      @visitor.visit_template(template)
      [
        {
          name: "b",
          attributes: {
            "a" => "{{}}",
            "b" => "{{}}",
            "c" => "{{}}",
            "d" => "{{}}",
            "x" => "{% %}",
            "y" => "{{ }}",
            "z" => "{{}}",
          },
        },
        {
          name: "b",
          attributes: {
            "a" => "{{}}",
            "b" => "{{}}",
            "c" => "{{}}",
            "d" => "{{}}",
            "x" => "{% %}",
            "y" => "{{ }}",
            "z" => "{{}}",
          },
        },
        {
          name: "b",
          attributes: {
            "a" => "{{}}",
            "b" => "{{}}",
            "c" => "{{}}",
            "d" => "{{}}",
            "x" => "{% %}",
            "y" => "{{ }}",
            "z" => "{{}}",
          },
        },
      ].each_with_index do |element, i|
        assert_equal(element, @attribute_checker.elements[i], "i #{i}")
      end
    end

    class HTMLAttributeIntegrityMockCheck < Check
      attr_reader :elements

      def initialize
        @elements = []
      end

      def on_element(node)
        elements.push({
          name: node.name,
          attributes: node.attributes,
        })
      end
    end
  end
end
