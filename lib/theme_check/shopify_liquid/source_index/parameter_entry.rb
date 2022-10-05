# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class ParameterEntry < BaseEntry
        def summary
          nil
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
