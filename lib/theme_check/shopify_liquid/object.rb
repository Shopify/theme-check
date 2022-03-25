# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
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
