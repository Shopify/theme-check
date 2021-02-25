# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class TagCompletionProviderTest < Minitest::Test
      def setup
        @module = TagCompletionProvider.new
      end

      def test_can_complete?
        assert(@module.can_complete?("{% ", 3))
        assert(@module.can_complete?("{%  ", 4))
        assert(@module.can_complete?("{% rend", 3))
        assert(@module.can_complete?("{% rend", 7))
        assert(@module.can_complete?("{% rend %}", 3))

        refute(@module.can_complete?("{{  ", 4))
        refute(@module.can_complete?("{% if foo", 9))
      end

      def test_completions
        assert_includes(@module.completions("{% rend", 7), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
        assert_includes(@module.completions("{% comm", 7), {
          label: "comment",
          kind: CompletionItemKinds::KEYWORD,
        })
      end
    end
  end
end
