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
        @all ||= SourceIndex.deprecated_filters
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
