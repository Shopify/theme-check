# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
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
        source = node.theme_file.source
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
        @theme_file = node.theme_file
      end

      def on_end
        offenses << Offense.new(check: self, message: "on_end used", theme_file: @theme_file)
      end
    end

    def setup
      @assign_check = AssignCheck.new
      @regex_check = RegexCheck.new
      @on_end_check = OnEndCheck.new
      @checks = Checks.new([@assign_check, @regex_check, @on_end_check])
      @disabled_checks = DisabledChecks.new
      @visitor = LiquidVisitor.new(@checks, @disabled_checks)
    end

    def block_comment(text)
      "{% comment %}#{text}{% endcomment %}"
    end

    def inline_comment(text)
      "{% # #{text} %}"
    end

    def comment_types
      [
        -> (text) { block_comment(text) },
        -> (text) { inline_comment(text) },
      ]
    end

    def test_ignore_all_checks
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable')}
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call('theme-check-enable')}
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@assign_check.offenses)
        assert_empty(@regex_check.offenses)
      end
    end

    def test_ignore_all_checks_issue_583
      liquid_file = parse_liquid(<<~END)
        {% comment %}theme-check-disable{% endcomment %}
        {% comment %}
          This is some comment about the file...
          Adding a comment here should not mess with theme-check-disable
        {% endcomment %}
        {% assign x = 'x' %}
        RegexError 1
        {% comment %}theme-check-enable{% endcomment %}
      END
      @visitor.visit_liquid_file(liquid_file)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses)
      assert_empty(@regex_check.offenses)
    end

    def test_ignore_all_checks_without_end
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable')}
          {% assign x = 'x' %}
          RegexError 1
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@assign_check.offenses)
        assert_empty(@regex_check.offenses)
      end
    end

    def test_ignore_all_checks_between_bounds
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call('theme-check-disable')}
          {% assign y = 'y' %}
          RegexError 2
          #{comment.call('theme-check-enable')}
          {% assign z = 'z' %}
          RegexError 3
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_includes(@assign_check.offenses.map(&:markup), "assign x = 'x' ")
        refute_includes(@assign_check.offenses.map(&:markup), "assign y = 'y' ")
        assert_includes(@assign_check.offenses.map(&:markup), "assign z = 'z' ")
        assert_includes(@regex_check.offenses.map(&:markup), "RegexError 1")
        refute_includes(@regex_check.offenses.map(&:markup), "RegexError 2")
        assert_includes(@regex_check.offenses.map(&:markup), "RegexError 3")
      end
    end

    def test_ignore_specific_checks
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable AssignCheck')}
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call('theme-check-enable AssignCheck')}
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@assign_check.offenses)
        refute_empty(@regex_check.offenses)
      end
    end

    def test_ignore_multiple_checks
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable AssignCheck, RegexCheck')}
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call('theme-check-enable AssignCheck, RegexCheck')}
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@assign_check.offenses)
        assert_empty(@regex_check.offenses)
      end
    end

    def test_enable_specific_checks_individually
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable AssignCheck, RegexCheck')}
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call('theme-check-enable AssignCheck')}
          {% assign y = 'y' %}
          RegexError 2
          #{comment.call('theme-check-enable RegexCheck')}
          {% assign z = 'z' %}
          RegexError 3
        END
        @visitor.visit_liquid_file(liquid_file)
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
    end

    def test_comments_can_have_spaces
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call(' theme-check-disable ')}
          {% assign x = 'x' %}
          RegexError 1
          #{comment.call(' theme-check-enable ')}
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@assign_check.offenses)
        assert_empty(@regex_check.offenses)
      end
    end

    def test_ignore_disable_check_that_cant_be_disabled
      comment_types.each do |comment|
        RegexCheck.can_disable(false)
        liquid_file = parse_liquid(<<~END)
          #{comment.call(' theme-check-disable ')}
          RegexError 1
          #{comment.call(' theme-check-enable ')}
          #{comment.call(' theme-check-disable RegexCheck ')}
          RegexError 2
          #{comment.call(' theme-check-enable RegexCheck ')}
        END
        @visitor.visit_liquid_file(liquid_file)
        @disabled_checks.remove_disabled_offenses(@checks)
        RegexCheck.can_disable(true)

        assert_empty(@assign_check.offenses)
        assert_includes(@regex_check.offenses.map(&:markup), "RegexError 1")
        assert_includes(@regex_check.offenses.map(&:markup), "RegexError 2")
      end
    end

    def test_can_disable_check_that_run_on_end
      comment_types.each do |comment|
        liquid_file = parse_liquid(<<~END)
          #{comment.call('theme-check-disable OnEndCheck')}
          Hello there
        END
        @visitor.visit_liquid_file(liquid_file)
        @checks.call(:on_end)
        @disabled_checks.remove_disabled_offenses(@checks)

        assert_empty(@on_end_check.offenses.map(&:theme_file))
      end
    end

    def test_can_ignore_check_using_pattern
      liquid_file = parse_liquid(<<~END)
        {% assign x = 'x' %}
      END
      @assign_check.ignored_patterns = [
        liquid_file.relative_path.to_s,
      ]
      @visitor.visit_liquid_file(liquid_file)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@assign_check.offenses.map(&:theme_file))
    end

    def test_should_ignore_regex_checks_inside_comments
      liquid_file = parse_liquid(<<~END)
        {% comment %}
          RegexError 1
        {% endcomment %}
      END
      @assign_check.ignored_patterns = [
        liquid_file.relative_path.to_s,
      ]
      @visitor.visit_liquid_file(liquid_file)
      @disabled_checks.remove_disabled_offenses(@checks)

      assert_empty(@regex_check.offenses)
    end
  end
end
