# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class HtmlAttributeCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = HtmlAttributeCompletionProvider.new
      end

      def test_can_complete?
        assert_can_complete(@provider, "<a ", 0, 'a')
        assert_can_complete(@provider, "<a hr", 0, 'a')
        assert_can_complete(@provider, "<a href", 0, 'a')

        refute_can_complete(@provider, "<a href=", 0, 'a')
        refute_can_complete(@provider, "</")
        refute_can_complete(@provider, "</he")
        refute_can_complete(@provider, "</head ")
        refute_can_complete(@provider, "{{ 'foo.js' ")
        refute_can_complete(@provider, "{% if foo")
      end

      def test_completions
        assert_can_complete_with(@provider, "<a hr", "href", 0, 'a')
        assert_can_complete_with(@provider, "<script ", "src", 0, 'script')
      end
    end
  end
end
