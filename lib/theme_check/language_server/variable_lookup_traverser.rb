# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupTraverser
      extend self

      def lookup_object_and_property(potential_lookup)
        object, generic_type = find_object_and_generic_type(potential_lookup)
        property = nil

        potential_lookup.lookups.each do |name|
          prop = find_property(object, name)

          next unless prop

          generic_type = generic_type(prop) if generic_type?(prop)

          property = prop
          property.return_type = generic_type if prop.generic_type?
          object = find_object(prop.return_type)
        end

        [object, property]
      end

      def find_object_and_generic_type(potential_lookup)
        generic_type = nil
        object = find_object(potential_lookup.name)

        # Objects like 'product' are a complex structure with fields
        # and their return type is not present.
        #
        # However, we also handle objects that have simple built-in types,
        # like 'current_tags', which is an 'array'. So, we follow them until
        # the source type:
        while object&.return_type
          generic_type = generic_type(object) if generic_type?(object)
          object = find_object(object.return_type)
        end

        [object, generic_type]
      end

      # Currently, we're handling generic types only for arrays,
      # so we get the array type
      def generic_type(object)
        object.array_type
      end

      # Currently, we're handling generic types only for arrays,
      # so we check if it's an array type
      def generic_type?(object)
        object.array_type?
      end

      def find_property(object, property_name)
        object
          &.properties
          &.find { |property| property.name == property_name }
      end

      def find_object(object_name)
        ShopifyLiquid::SourceIndex
          .objects
          .find { |entry| entry.name == object_name }
      end
    end
  end
end
