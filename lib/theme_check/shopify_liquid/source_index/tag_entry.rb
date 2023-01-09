# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class TagEntry < BaseEntry
        def parameters
          (hash['parameters'] || [])
            .map { |hash| ParameterEntry.new(hash) }
        end

        def return_type_hash
          {
            'type' => "tag<#{name}>",
          }
        end

        def shopify_dev_url
          "#{SHOPIFY_DEV_ROOT_URL}/tags/#{hash['name']}"
        end
      end
    end
  end
end
