# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Object
      extend self

      def labels
        @labels ||= begin
          YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/objects.yml"))
        end
      end

      def plus_labels
        @plus_labels ||= begin
          YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/plus_objects.yml"))
        end
      end
    end
  end
end
