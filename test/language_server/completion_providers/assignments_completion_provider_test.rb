# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class AssignmentsCompletionProviderTest < Minitest::Test
      include CompletionProviderTestHelper

      def setup
        @provider = AssignmentsCompletionProvider.new
        @token = <<~LIQUID
          {%- liquid
            assign target = cart
            assign product_2 = product
          %}
          {{
        LIQUID
      end

      def test_suggests_assigned_variables
        ShopifyLiquid::Documentation.expects(:object_doc).with("cart")
        ShopifyLiquid::Documentation.expects(:object_doc).with("product")

        assert_can_complete_with(@provider, @token, 'product_2')
      end

      def test_does_not_suggest_global_objects
        refute_can_complete_with(@provider, @token, 'cart')
        refute_can_complete_with(@provider, @token, 'product')
      end

      def test_suggests_nothing_when_method_of_object_is_called
        refute_can_complete(@provider, "#{@token} target.")
        refute_can_complete(@provider, "#{@token} target.prod")
      end
    end
  end
end
