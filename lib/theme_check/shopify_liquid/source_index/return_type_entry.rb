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

        def array_type?
          !hash['array_value'].empty?
        end

        def array_type
          hash['array_value']
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
