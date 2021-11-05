# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProviderTest < Minitest::Test
      def setup
        instances = diagnose_theme(
          ThemeCheck::SpaceInsideBraces.new,
          ThemeCheck::TemplateLength.new(max_length: 0),
          "index.liquid" => <<~LIQUID,
            {{xx}}
            muffin
          LIQUID
          "other.liquid" => <<~LIQUID,
            cookies
          LIQUID
        )
        @storage = instances[:storage]
        @diagnostics_manager = instances[:diagnostics_manager]
        @provider = QuickfixCodeActionProvider.new(@storage, @diagnostics_manager)
      end

      def test_returns_relevant_code_actions_if_cursor_covers_diagnostic
        expected_diagnostic = @diagnostics_manager
          .diagnostics("index.liquid")
          .find { |d| d.code == "SpaceInsideBraces" && d.start_index == 2 }
        code_actions = @provider.code_actions("index.liquid", (0..2))
        code_action = code_actions[0]
        assert_equal(1, code_actions.size)
        assert_equal('quickfix', code_action.dig(:kind))
        assert_equal([expected_diagnostic.to_h], code_action.dig(:diagnostics))
        assert_equal('quickfix', code_action.dig(:command, :title))
        assert_equal(CorrectionExecuteCommandProvider.command, code_action.dig(:command, :command))
        assert_equal([expected_diagnostic.to_h], code_action.dig(:command, :arguments))
      end

      def test_returns_empty_array_if_versions_dont_match
        @storage.write('index.liquid', '{{ look ma I fixed it }}', 1000)
        assert_equal([], @provider.code_actions("index.liquid", (0..2)))
      end

      def test_returns_empty_array_if_range_does_not_cover_a_correctable_diagnostic
        assert_equal([], @provider.code_actions("index.liquid", (0..0)))
      end
    end
  end
end
