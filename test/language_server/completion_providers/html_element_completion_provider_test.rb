# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class HtmlElementCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = HtmlElementCompletionProvider.new
      end

      def test_can_complete?
        assert_can_complete(@provider, "<")
        assert_can_complete(@provider, "<head")

        refute_can_complete(@provider, "</")
        refute_can_complete(@provider, "</he")
        refute_can_complete(@provider, "</head ")
        refute_can_complete(@provider, "{{ 'foo.js' ")
        refute_can_complete(@provider, "{% if foo")
      end

      def test_completions
        assert_can_complete_with(@provider, "<he", "head")
        assert_can_complete_with(@provider, "<di", "div")
      end
    end
  end
end
