# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class FilterEntry < BaseEntry
        def parameters
          (hash['parameters'] || [])
            .map { |hash| ParameterEntry.new(hash) }
        end

        def input_type
          @input_type ||= hash['syntax'].split(' | ')[0]
        end

        def shopify_dev_url
          "#{SHOPIFY_DEV_ROOT_URL}/filters/#{hash['name']}"
        end
      end
    end
  end
end
