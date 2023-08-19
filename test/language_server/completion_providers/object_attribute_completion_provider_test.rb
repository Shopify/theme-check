# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class ObjectAttributeCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = ObjectAttributeCompletionProvider.new
      end

      def test_completions_when_it_completes_variable_lookups
        assert_can_complete_with(@provider, '{{ cart.', 'total_price')
        assert_can_complete_with(@provider, '{{- cart.', 'total_price')
        assert_can_complete_with(@provider, '{{ cart.disc', 'discount_applications')
        assert_can_complete_with(@provider, "{{ cart['disc", 'discount_applications')
        assert_can_complete_with(@provider, "{{ cart['disc'", 'discount_applications', -1)
        assert_can_complete_with(@provider, '{{ cart["disc"]', 'discount_applications', -2)
        assert_can_complete_with(@provider, '{{ cart. }}', 'total_price', -3)
      end

      def test_completions_when_it_completes_filter_arguments
        assert_can_complete_with(@provider, '{{ 0 | plus: current_tags.si', 'size')
        assert_can_complete_with(@provider, "{{ 0 | plus: current_tags['", 'size', -2)
        assert_can_complete_with(@provider, "{{ 0 | plus: current_tags['']", 'size', -2)
        assert_can_complete_with(@provider, "{{ 0 | plus: current_tags[\"", 'size', -2)
      end

      def test_completions_when_it_completes_filter_hash_arguments
        assert_can_complete_with(@provider, "{{ 0 | plus: bogus: current_tags.si", 'size')
      end

      def test_completions_when_it_completes_tag_arguments
        assert_can_complete_with(@provider, "{% if form.", 'author')
        assert_can_complete_with(@provider, "{%- if form.", 'author')
      end

      def test_completions_when_it_completes_array_types
        assert_can_complete_with(@provider, "{{ articles.first.", 'comments')
        assert_can_complete_with(@provider, "{{ product.images.first.", 'alt')
      end

      def test_completions_when_it_completes_nested_attributes
        assert_can_complete_with(@provider, '{{ product.featured_image.', 'src')
        assert_can_complete_with(@provider, '{{ product.featured_image.src', 'size')
        assert_can_complete_with(@provider, '{{ product.featured_image.src.', 'size')
      end

      def test_completions_when_it_should_not_complete_non_attributes
        refute_can_complete(@provider, '{{ pro')
        refute_can_complete(@provider, '{% rend')
        refute_can_complete(@provider, "{% render '")
        refute_can_complete(@provider, 'some text')
      end

      def test_completions_when_it_has_multiple_dots
        refute_can_complete(@provider, '{{ cart..')
      end
    end
  end
end
