# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class FilterCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = FilterCompletionProvider.new
      end

      def test_can_complete?
        assert_can_complete(@provider, "{{ 'foo.js' | ")
        assert_can_complete(@provider, "{{ 'foo.js' | asset")
        assert_can_complete(@provider, "{{ 'foo.js' | asset_url | ")
        assert_can_complete(@provider, "{{ 'foo.js' | asset_url | img")

        refute_can_complete(@provider, "{{ 'foo.js' ")
        refute_can_complete(@provider, "{% if foo")
      end

      def test_completions
        assert_can_complete_with(@provider, "{{ 'foo.js' | ", "asset_url")
        assert_can_complete_with(@provider, "{{ 'foo.js' | asset", "asset_url")
        assert_can_complete_with(@provider, "{{ 'foo.js' | asset_url | img", "img_url")
      end

      def test_does_not_complete_deprecated_filters
        refute_can_complete_with(@provider, "{{ 'foo.js' | hex_to", "hex_to_rgba")
      end
    end
  end
end
