# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class ObjectEntry < BaseEntry
        def properties
          (hash['properties'] || [])
            .map do |prop_hash|
              PropertyEntry.new(prop_hash, hash['name'])
            end
        end

        def shopify_dev_url
          "#{SHOPIFY_DEV_ROOT_URL}/objects/#{hash['name']}"
        end
      end
    end
  end
end
