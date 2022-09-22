# frozen_string_literal: true

module ThemeCheck
  class Resource
    class ShopContextStub
      def self.metaobject_definitions
        {
          1 => {
            type: "team_member"
          },
          2 => {
            type: "project"
          }
        }
      end

      def self.metafield_definitions
        ## hash key in format <owner_type>.<namespace>.<key>
        {
          "product.custom.created_by" => {
            type: "metaobject_reference",
            validations: [{name: "metaobject_definition_id", value: 1}]
          },
          "metaobject.team_member.name" => {
            type: "single_line_text_field",
            validations: [],
          },
          "metaobject.team_member.projects" => {
            type: "metaobject_reference",
            validations: [{name: "metaobject_definition_id", value: 2}]
          },
          "metaobject.project.title" => {
            type: "single_line_text_field",
            validations: []
          }
        }
      end

      def self.metafield_definition(owner_type:, namespace:, key:)
        self.metafield_definitions["#{owner_type}.#{namespace}.#{key}"]
      end

      def self.metaobject_definition_by_id(id:)
        self.metaobject_definitions[id]
      end

      def self.metaobject_definition_by_type(type:)
        binding.pry
      end
    end

    class Metafield
      attr_reader :namespace, :key, :owner_type
      def initialize(namespace:, key:, owner_type:)
        @namespace = namespace
        @key = key
        @owner_type = owner_type
      end

      def definition
        ShopContextStub.metafield_definition(namespace: @namespace, key: @key, owner_type: @owner_type)
      end

      def referenced_resource(name:)
        return nil unless definition
        case definition[:type]
        when 'metaobject_reference'
          metaobject_definition_id = definition[:validations].find { |validation| validation[:name] == "metaobject_definition_id" }[:value]
          metaobject_definition = ShopContextStub.metaobject_definition_by_id(id: metaobject_definition_id)
          Resource.new(
            name: name,
            resource_type: "metaobject.#{metaobject_definition[:type]}",
            metafields: []
          )
        end
      end

      def as_json
        {
          namespace: @namespace,
          key: @key,
          owner_type: @owner_type
        }
      end
    end

    attr_reader :name, :resource_type
    attr_accessor :metafields
    def initialize(name:, resource_type:, metafields:)
      @name = name
      @resource_type = resource_type
      @metafields = []
    end

    def metafield_from_lookups(lookups:)
      if (@resource_type.include?("metaobject"))
        return Metafield.new(
          namespace: @resource_type.split(".")[1],
          key: lookups[0],
          owner_type: "metaobject"
        )
      end

      if lookups[0] == "metafields"
        _, namespace, key, value = lookups
        return Metafield.new(
          namespace: namespace,
          key: key,
          owner_type: @resource_type
        )
      end
    end

    def as_json
      {
        name: @name,
        resource_type: @resource_type,
        metafields: @metafields.map(&:as_json)
      }
    end
  end
end
