# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class ScopeIndex
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
      end
    end
  end
end
