# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class FilterCompletionProviderTest < Minitest::Test
      def setup
        @module = FilterCompletionProvider.new
      end

      def test_can_complete?
        assert(@module.can_complete?("{{ 'foo.js' | asset", 19))
        assert(@module.can_complete?("{{ 'foo.js' | ", 14))

        refute(@module.can_complete?("{{ 'foo.js' ", 4))
        refute(@module.can_complete?("{% if foo", 9))
      end

      def test_completions
        assert_includes(@module.completions("{{ 'foo.js' | asset", 19), {
          label: "asset_url",
          kind: CompletionItemKinds::FUNCTION,
        })
        assert_includes(@module.completions("{{ 'foo.js' | ", 14), {
          label: "asset_url",
          kind: CompletionItemKinds::FUNCTION,
        })
      end
    end
  end
end
