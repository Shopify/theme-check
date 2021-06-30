# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class ObjectCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = ObjectCompletionProvider.new
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_completions_from_different_cursor_positions
        # variables
        assert_can_complete(@provider, "{{ ")
        assert_can_complete(@provider, "{{ all_")

        # Cursor inside the token
        assert_can_complete(@provider, "{{ all_ }}", -3)

        # filters
        assert_can_complete(@provider, "{{ '1234' | replace: prod")

        # for loops
        assert_can_complete(@provider, "{% for p in all_")
        assert_can_complete(@provider, "{% for p in all_ %}", -3)

        # case statements
        assert_can_complete(@provider, "{% case all_prod")
        assert_can_complete(@provider, "{% when all_prod")

        # render attributes
        assert_can_complete(@provider, "{% render 'snippet', products: all_")

        # out of bounds for completions
        refute_can_complete(@provider, "{{")
        refute_can_complete(@provider, "{{ all_prod ")
        refute_can_complete(@provider, "{{ all_prod }")
        refute_can_complete(@provider, "{{ all_prod }}")

        # not an object.
        refute_can_complete(@provider, "{{ all_products.")
        refute_can_complete(@provider, "{{ all_products. ")
        refute_can_complete(@provider, "{{ all_products.featured_image ")

        # not completable
        refute_can_complete(@provider, "{%  ")
        refute_can_complete(@provider, "{% rend")
      end

      def test_correctly_suggests_things
        assert_can_complete_with(@provider, "{{ ", 'all_products')
        assert_can_complete_with(@provider, "{{  ", 'all_products')
        assert_can_complete_with(@provider, "{{ all_", 'all_products')

        refute_can_complete_with(@provider, "{{ all_", 'cart')
      end
    end
  end
end
