# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    # TODO: (1/X): https://github.com/shopify/theme-check/issues/n
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
