# frozen_string_literal: true
require "test_helper"

class DisabledChecksTest < Minitest::Test
  class TracerOne < TracerCheck; end

  class TracerTwo < TracerCheck; end

  def setup
    @tracer_one = TracerOne.new
    @tracer_two = TracerTwo.new
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

    refute_includes(@tracer_one.calls, :on_assign)

    refute_includes(@tracer_two.calls, :on_assign)
  end

  def test_ignore_specific_checks
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOne{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOne{% endcomment %}
    END
    @visitor.visit_template(template)

    refute_includes(@tracer_one.calls, :on_assign)

    assert_includes(@tracer_two.calls, :on_assign)
  end

  def test_ignore_multiple_checks_including_tracer
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOne, TracerTwo{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOne, TracerTwo{% endcomment %}
    END
    @visitor.visit_template(template)

    refute_includes(@tracer_one.calls, :on_assign)

    refute_includes(@tracer_two.calls, :on_assign)
  end

  def test_enable_specific_checks_individually
    template = parse_liquid(<<~END)
      {% comment %}theme-check-disable TracerOne, TracerTwo{% endcomment %}
      {% assign x = 'hello' %}
      {% comment %}theme-check-enable TracerOne{% endcomment %}
      Hello
      {% comment %}theme-check-enable TracerTwo{% endcomment %}
      Everybody
    END
    @visitor.visit_template(template)

    refute_includes(@tracer_one.calls, :on_assign)
    assert_includes(@tracer_one.calls, "\nHello\n")
    assert_includes(@tracer_one.calls, "\nEverybody\n")

    refute_includes(@tracer_two.calls, :on_assign)
    refute_includes(@tracer_two.calls, "\nHello\n")
    assert_includes(@tracer_two.calls, "\nEverybody\n")
  end
end
