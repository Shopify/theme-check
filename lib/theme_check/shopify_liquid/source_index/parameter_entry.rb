# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class ParameterEntry < BaseEntry
        def summary
          nil
        end

        def shopify_dev_url
          "#{SHOPIFY_DEV_ROOT_URL}/filters/#{hash['name']}"
        end

        private

        def return_type_hash
          {
            'type' => (hash['types'] || ['untyped']).first,
          }
        end
      end
    end
  end
end
