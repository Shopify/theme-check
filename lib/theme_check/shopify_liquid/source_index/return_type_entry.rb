# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class ReturnTypeEntry < BaseEntry
        def summary
          nil
        end

        def to_s
          hash['type']
        end

        def generic_type?
          hash['type'] == 'generic'
        end

        def array_type?
          !array_type.nil? && !array_type.empty?
        end

        def array_type
          hash['array_value']
        end

        def denied_filters
          hash['denied_filters'] || []
        end

        private

        def return_type_hash
          {
            'type' => "type<#{self}>",
          }
        end
      end
    end
  end
end
