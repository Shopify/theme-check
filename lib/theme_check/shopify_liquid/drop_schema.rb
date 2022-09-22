# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class DropSchema
      attr_accessor :parent_schema, :lookup_name
      def initialize(shop_context:, parent_schema: nil, lookup_name: nil)
        @shop_context = shop_context
        @parent_schema = parent_schema
        @lookup_name = lookup_name
        @properties = self.class.properties
        @has_metafields = self.class.is_metafield_owner
      end


      class Property
        attr_accessor :name, :returns
        def initialize(name:, returns:)
          @name = name
          @returns = returns
        end
      end

      def self.has_metafields
        @is_metafield_owner ||= true
      end

      def self.is_metafield_owner
        has_metafields || false
      end

      def self.property(name, returns)
        properties << Property.new(name: name, returns: returns)
      end

      def self.properties
        @properties ||= []
      end

      def name
        self.class.name.split("::").last
      end

      def metafield_owner_type
        if @has_metafields
          name
        end
      end

      def property_by_name(name)
        property = properties_by_name[name] || dynamic_property || nil
        if (property.kind_of?(Proc))
          property = property.call(self)
        end
        property
      end

      def properties_by_name
        @properties_by_name ||= begin
          by_name = {}
          @properties.each do |property|
            return_schema = property.returns
            by_name[property.name] = return_schema.kind_of?(Array) ? return_schema.first : return_schema
          end
          by_name
        end
      end

      def dynamic_property
        properties_by_name["*"]
      end
    end
  end
end
