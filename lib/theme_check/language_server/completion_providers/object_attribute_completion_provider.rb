# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectAttributeCompletionProvider < CompletionProvider
      def completions(context)
        content = context.content
        cursor = context.cursor

        return [] if content.nil?
        return [] unless (variable_lookup = VariableLookupFinder.lookup(context))
        return [] if content[cursor - 1] == "." && content[cursor - 2] == "."

        # Navigate through lookups until the last valid [object, property] level
        object, property = lookup_object_and_property(variable_lookup)

        # If the last lookup level is incomplete/invalid, use the partial term
        # to filter object properties.
        partial = partial_property_name(property, variable_lookup)

        return [] unless object

        object
          .properties
          .select { |prop| partial.nil? || prop.name.start_with?(partial) }
          .map { |prop| property_doc(prop) }
      end

      private

      def lookup_object_and_property(variable_lookup)
        object, generic_type = find_object_and_generic_type(variable_lookup)
        property = nil

        variable_lookup.lookups.each do |name|
          prop = find_property(object, name)

          next unless prop

          generic_type = generic_type(prop) if generic_type?(prop)

          property = prop
          property.return_type = generic_type if prop.generic_type?
          object = find_object(prop.return_type)
        end

        [object, property]
      end

      def find_object_and_generic_type(variable_lookup)
        generic_type = nil
        object = find_object(variable_lookup.name)

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

      def partial_property_name(property, variable_lookup)
        last_property = variable_lookup.lookups.last
        last_property if last_property != property&.name
      end

      def property_doc(prop)
        content = ShopifyLiquid::Documentation.render_doc(prop)

        {
          label: prop.name,
          kind: CompletionItemKinds::PROPERTY,
          **doc_hash(content),
        }
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
