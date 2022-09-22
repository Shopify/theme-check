# frozen_string_literal: true
require_relative 'drop_schema'

module ThemeCheck
  module ShopifyLiquid
    class DropSchemas
      class Metafield < DropSchema
        def initialize(shop_context:, parent_schema: nil, lookup_name: nil)
          @key = lookup_name
          @namespace = nil
          @owner_type = nil

          if parent_schema.kind_of?(ContentEntry)
            @owner_type = parent_schema.metafield_owner_type
            @namespace = parent_schema.instance_variable_get(:@type)
          else
            key_schema = parent_schema
            namespace_schema = key_schema.parent_schema
            owner_schema = namespace_schema.parent_schema
            @owner_type = owner_schema.metafield_owner_type
            @namespace = key_schema.lookup_name
          end

          @metafield_definition = ShopContextStub.metafield_definition(owner_type: @owner_type, namespace: @namespace, key: @key)
          @value = value_from_metafield_definition(@metafield_definition, ShopContextStub)
          super
        end

        property "value", -> (schema) { schema.instance_variable_get(:@value) }

        private

        def value_from_metafield_definition(definition, shop_context)
          if definition[:type] === "metaobject_reference"
            ContentEntry
          end
        end
      end

      class MetafieldNamespace < DropSchema
        property "*", Metafield
      end

      class MetafieldsPath < DropSchema
        property "*", MetafieldNamespace
      end

      class ProductVariant < DropSchema
        has_metafields
        property "metafields", MetafieldsPath
      end

      class Product < DropSchema
        has_metafields
        property "metafields", MetafieldsPath
        property "variants", [ProductVariant]
      end

      class Collection < DropSchema
        has_metafields
        property "metafields", MetafieldsPath
        property "products", [Product]
      end

      class ContentEntry < DropSchema
        def initialize(shop_context:, parent_schema: nil, lookup_name: nil)
          @type = begin
            if parent_schema.class.name.downcase.include?("metafield")
              metafield_definition = parent_schema.instance_variable_get(:@metafield_definition)
              nil unless metafield_definition
              metaobject_definition_id = metafield_definition[:validations].find {|validation| validation[:name] == "metaobject_definition_id"}[:value]
              nil unless metaobject_definition_id
              metaobject_definition = shop_context.metaobject_definitions[metaobject_definition_id]
              nil unless metaobject_definition
              metaobject_definition[:type]
            end
          end
          super
        end

        has_metafields
        property "*", Metafield
      end

      class Shop < DropSchema
        has_metafields
        property "metafields", MetafieldNamespace
      end
    end
  end
end
