# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    # TODO: (6/6) https://github.com/Shopify/theme-check/issues/656
    # -
    # Remove 'filters.yml' in favor of 'SourceIndex.filters'
    # -
    module Filter
      extend self

      def labels
        @labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/filters.yml"))
          .values
          .flatten
      end
    end
  end
end
