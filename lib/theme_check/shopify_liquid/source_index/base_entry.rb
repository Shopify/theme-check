# frozen_string_literal: true
require "forwardable"

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class BaseEntry
        extend Forwardable

        attr_reader :hash

        def_delegators :return_type_instance, :generic_type?, :array_type?, :array_type, :to_s

        def initialize(hash = {})
          @hash = hash || {}
          @return_type = nil
        end

        def name
          hash['name']
        end

        def summary
          hash['summary'] || ''
        end

        def description
          hash['description'] || ''
        end

        attr_writer :return_type

        def return_type
          @return_type || to_s
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
