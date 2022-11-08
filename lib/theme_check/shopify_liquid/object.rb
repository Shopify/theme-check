# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    # TODO: (4/6) https://github.com/Shopify/theme-check/issues/656
    # -
    # Remove 'objects.yml' in favor of 'SourceIndex.objects'
    # -
    module Object
      extend self

      def labels
        @labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/objects.yml"))
      end

      def plus_labels
        @plus_labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/plus_objects.yml"))
      end

      def theme_app_extension_labels
        @theme_app_extension_labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/theme_app_extension_objects.yml"))
      end
    end
  end
end
