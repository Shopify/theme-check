# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class PropertyEntry < BaseEntry
        attr_reader :parent_name

        def initialize(hash, parent_name)
          @hash = hash || {}
          @return_type = nil
          @parent_name = parent_name
        end

        def shopify_dev_url
          "#{SHOPIFY_DEV_ROOT_URL}/objects/#{parent_name}##{parent_name}-#{hash['name']}"
        end
      end
    end
  end
end
