# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class ObjectEntry < BaseEntry
        def properties
          (hash['properties'] || [])
            .map { |hash| PropertyEntry.new(hash) }
        end
      end
    end
  end
end
