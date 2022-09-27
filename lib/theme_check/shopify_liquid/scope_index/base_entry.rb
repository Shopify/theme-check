# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class ScopeIndex
      class BaseEntry
        attr_reader :hash

        def initialize(hash = {})
          @hash = hash
        end

        def name
          hash['name']
        end

        def summary
          hash['summary']
        end

        def description
          hash['description']
        end

        def return_type
          return_type_instance.to_s
        end

        def return_type_instance
          ReturnTypeEntry.new(return_type_hash)
        end

        private

        def return_type_hash
          hash['return_type']&.first
        end
      end
    end
  end
end
