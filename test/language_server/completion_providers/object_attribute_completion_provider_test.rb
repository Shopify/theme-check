# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class ObjectAttributeCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = ObjectAttributeCompletionProvider.new
      end

      def test_can_complete?
        # complete variable lookups
        assert_can_complete(@provider, "{{ cart.")
        assert_can_complete(@provider, "{{- cart.")
        assert_can_complete(@provider, "{{ cart.disc")
        assert_can_complete(@provider, "{{ cart['disc")
        assert_can_complete(@provider, "{{ cart['disc'", -1)
        assert_can_complete(@provider, '{{ cart["disc"]', -2)
        assert_can_complete(@provider, "{{ cart. }}", -3)

        # complete filter arguments
        assert_can_complete(@provider, "{{ 0 | plus: current_tags.si")
        assert_can_complete(@provider, "{{ 0 | plus: current_tags['", -2)
        assert_can_complete(@provider, "{{ 0 | plus: current_tags['']", -2)
        assert_can_complete(@provider, "{{ 0 | plus: current_tags[\"", -2)

        # complete filter hash arguments
        assert_can_complete(@provider, "{{ 0 | plus: bogus: current_tags.si")

        # complete tag arguments
        assert_can_complete(@provider, "{% if form.")
        assert_can_complete(@provider, "{%- if form.")

        # not yet
        refute_can_complete(@provider, "{{ product.featured_image.")
        refute_can_complete(@provider, "{{ product.featured_image.src")
        refute_can_complete(@provider, "{{ product.featured_image.src.")

        # stuff that isn't attributes
        refute_can_complete(@provider, "{{ pro")
        refute_can_complete(@provider, "{% rend")
        refute_can_complete(@provider, "{% render '")
        refute_can_complete(@provider, "some text")
      end

      def test_completions
        assert_can_complete_with(@provider, "{{ cart.", "discount")
        assert_can_complete_with(@provider, "{{ cart.disc", "discount")
        refute_can_complete_with(@provider, "{{ cart.disc", "count")
      end
    end
  end
end
