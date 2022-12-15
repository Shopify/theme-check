# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Object
      extend self

      LABELS_NOT_IN_SOURCE_INDEX = [
        "customer_address",
        "product_variant",
      ].freeze

      def labels
        @labels ||= SourceIndex.objects.map(&:name) + LABELS_NOT_IN_SOURCE_INDEX
      end

      def plus_labels
        @plus_labels ||= SourceIndex.plus_labels
      end

      def theme_app_extension_labels
        @theme_app_extension_labels ||= SourceIndex.theme_app_extension_labels
      end
    end
  end
end
