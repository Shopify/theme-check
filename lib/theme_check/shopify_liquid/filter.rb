# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Filter
      extend self

      def labels
        @labels ||= begin
          YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/filters.yml"))
            .values
            .flatten
        end
      end
    end
  end
end
