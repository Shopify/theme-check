# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class ObjectCompletionProviderTest < Minitest::Test
      def setup
        @module = ObjectCompletionProvider.new
      end

      def test_can_complete?
        assert(@module.can_complete?("{{ ", 3))
        assert(@module.can_complete?("{{  ", 4))
        assert(@module.can_complete?("{{ all_", 3))
        assert(@module.can_complete?("{{ all_", 7))
        assert(@module.can_complete?("{{ all_ }}", 3))

        refute(@module.can_complete?("{%  ", 4))
        refute(@module.can_complete?("{% rend", 9))
      end

      def test_completions
        assert_includes(@module.completions("{{ all_", 7), {
          label: "all_products",
          kind: CompletionItemKinds::VARIABLE,
        })
        assert_includes(@module.completions("{{ prod", 7), {
          label: "product",
          kind: CompletionItemKinds::VARIABLE,
        })
      end
    end
  end
end
