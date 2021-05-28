# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class DisabledChecksTest < Minitest::Test
    # This check flags uses of the assign tag.
    class AssignCheck < Check
      def on_assign(node)
        offenses << Offense.new(check: self, message: "assign used", node: node)
      end
    end

    # This check flags /RegexError \d+/ in the document
    class RegexCheck < Check
      include RegexHelpers

      def initialize
        @regex = /RegexError \d+/
        @offenses = []
      end

      def on_document(node)
        source = node.template.source
        matches(source, @regex).each do |match|
          offenses << Offense.new(
            check: self,
            message: "Regex found #{match[0]}.",
            node: node,
            markup: match[0],
            line_number: source[0...match.begin(0)].count("\n") + 1
          )
        end
      end
    end

    # A check that uses the on_end callback
    class OnEndCheck < Check
      def on_document(node)
        @template = node.template
      end

      def on_end
        offenses << Offense.new(check: self, message: "on_end used", template: @template)
      end
    end

    def setup
      @assign_check = AssignCheck.new
      @regex_check = RegexCheck.new
      @on_end_check = OnEndCheck.new
      @checks = Checks.new([@assign_check, @regex_check, @on_end_check])
      @disabled_checks = DisabledChecks.new
      @visitor = Visitor.new(@checks, @disabled_checks)
    end

    def test_ignore_all_checks
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-enable{% endcomment %}
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      assert_empty(@regex_check.offenses)
    end

    def test_ignore_all_checks_without_end
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable{% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      assert_empty(@regex_check.offenses)
    end

    def test_ignore_all_checks_between_bounds
      template = parse_liquid(<<~END)
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-disable{% endcomment %}
        {% assign y = 'y' %}
        RegexError 2
        {% comment %}theme-check-enable{% endcomment %}
        {% assign z = 'z' %}
        RegexError 3
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_includes(@assign_check.offenses.map(&:markup), "assign x = 'x' ")
      refute_includes(@assign_check.offenses.map(&:markup), "assign y = 'y' ")
      assert_includes(@assign_check.offenses.map(&:markup), "assign z = 'z' ")
      assert_includes(@regex_check.offenses.map(&:markup), "RegexError 1")
      refute_includes(@regex_check.offenses.map(&:markup), "RegexError 2")
      assert_includes(@regex_check.offenses.map(&:markup), "RegexError 3")
    end

    def test_ignore_specific_checks
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable AssignCheck{% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-enable AssignCheck{% endcomment %}
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      refute_empty(@regex_check.offenses)
    end

    def test_ignore_multiple_checks
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable AssignCheck, RegexCheck{% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-enable AssignCheck, RegexCheck{% endcomment %}
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      assert_empty(@regex_check.offenses)
    end

    def test_enable_specific_checks_individually
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable AssignCheck, RegexCheck{% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-enable AssignCheck{% endcomment %}
        {% assign y = 'y' %}
        RegexError 2
        {% comment %}theme-check-enable RegexCheck{% endcomment %}
        {% assign z = 'z' %}
        RegexError 3
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      refute_empty(@assign_check.offenses)
      refute_includes(@assign_check.offenses.map(&:markup), "assign x = 'x' ")
      assert_includes(@assign_check.offenses.map(&:markup), "assign y = 'y' ")
      assert_includes(@assign_check.offenses.map(&:markup), "assign z = 'z' ")

      refute_empty(@regex_check.offenses)
      refute_includes(@regex_check.offenses.map(&:markup), "RegexError 1")
      refute_includes(@regex_check.offenses.map(&:markup), "RegexError 2")
      assert_includes(@regex_check.offenses.map(&:markup), "RegexError 3")
    end

    def test_comments_can_have_spaces
      template = parse_liquid(<<~END)
        {% comment %} theme-check-disable {% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %} theme-check-enable {% endcomment %}
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      assert_empty(@regex_check.offenses)
    end

    def test_ignore_disable_check_that_cant_be_disabled
      RegexCheck.can_disable(false)
      template = parse_liquid(<<~END)
        {% comment %} theme-check-disable {% endcomment %}
        RegexError 1
        {% comment %} theme-check-enable {% endcomment %}
        {% comment %} theme-check-disable RegexCheck {% endcomment %}
        RegexError 2
        {% comment %} theme-check-enable RegexCheck {% endcomment %}
      END
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)
      RegexCheck.can_disable(true)

      assert_empty(@assign_check.offenses)
      assert_includes(@regex_check.offenses.map(&:markup), "RegexError 1")
      assert_includes(@regex_check.offenses.map(&:markup), "RegexError 2")
    end

    def test_can_disable_check_that_run_on_end
      template = parse_liquid(<<~END)
        {% comment %}theme-check-disable OnEndCheck{% endcomment %}
        Hello there
      END
      @visitor.visit_template(template)
      @checks.call(:on_end)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@on_end_check.offenses.map(&:template))
    end

    def test_can_ignore_check_using_pattern
      template = parse_liquid(<<~END)
        {% assign x = 'x' %}
      END
      @assign_check.ignored_patterns = [
        template.relative_path.to_s,
      ]
      @visitor.visit_template(template)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses.map(&:template))
    end
  end
end
