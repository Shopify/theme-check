# frozen_string_literal: true
require_relative 'drop_schemas'

module ThemeCheck
  module ShopifyLiquid
    class TemplateSchemas
      class Product < TemplateSchema
        global_drop "product", DropSchemas::Product
      end

      class Collection < TemplateSchema
        global_drop "collection", DropSchemas::Collection
      end
    end
  end
end
