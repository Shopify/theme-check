# frozen_string_literal: true
require_relative "drop_schemas"

module ThemeCheck
  module ShopifyLiquid
    class TemplateSchema
      def self.global_drop(name, returns)
        global_drops[name] = returns
      end

      def self.global_drops
        @global_drops ||= {
          "shop" => DropSchemas::Shop,
        }
      end
    end
  end
end
