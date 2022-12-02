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
          hash['syntax'].split(' | ')[0]
        end
      end
    end
  end
end
