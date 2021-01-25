# frozen_string_literal: true
require "test_helper"

class DisabledChecksTest < Minitest::Test
  def setup
    @tracer_one = TracerCheck.new
    @tracer_two = TracerCheck.new
    @tracer_one.stubs(:code_name).returns('TracerOneCheck')
    @tracer_two.stubs(:code_name).returns('TracerTwoCheck')
    @visitor = ThemeCheck::Visitor.new(ThemeCheck::Checks.new([@tracer_one, @tracer_two]))
  end

  def test_ignore_all_checks
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
    ], @tracer_one.calls)

    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\nhello\n",
      :after_document
    ], @tracer_two.calls)
  end

  def test_ignore_specific_checks
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOneCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOneCheck{% endcomment %}
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
    ], @tracer_one.calls)

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
    ], @tracer_two.calls)
  end

  def test_ignore_multiple_checks_including_tracer
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOneCheck, TracerTwoCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOneCheck, TracerTwoCheck{% endcomment %}
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
    ], @tracer_one.calls)

    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\n",
      :after_document
    ], @tracer_two.calls)
  end

  def test_enable_specific_checks_individually
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOneCheck, TracerTwoCheck{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOneCheck{% endcomment %}
      Hello
      {% comment %}theme-check-enable TracerTwoCheck{% endcomment %}
      Everybody
    END
    @visitor.visit_template(template)

    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\nHello\n",
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\nEverybody\n",
      :after_document
    ], @tracer_one.calls)

    assert_equal([
      :on_document,
      :on_tag,
      :on_comment,
      :after_comment,
      :after_tag,
      :on_string, "\nEverybody\n",
      :after_document
    ], @tracer_two.calls)
  end
end
