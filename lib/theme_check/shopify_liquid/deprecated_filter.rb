# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module DeprecatedFilter
      extend self

      def alternatives(filter)
        all.fetch(filter, nil)
      end

      def labels
        @labels ||= all.keys
      end

      private

      def all
        @all ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/deprecated_filters.yml"))
          .values
          .each_with_object({}) do |filters, acc|
          filters.each do |(filter, alternatives)|
            acc[filter] = alternatives
          end
        end
      end
    end
  end
end
