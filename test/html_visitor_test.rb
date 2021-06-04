# frozen_string_literal: true
require "test_helper"

class HtmlVisitorTest < Minitest::Test
  def setup
    @tracer = TracerCheck.new
    @visitor = ThemeCheck::HtmlVisitor.new(ThemeCheck::Checks.new([@tracer]))
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
end
