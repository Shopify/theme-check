# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectAttributeCompletionProvider < CompletionProvider
      def completions(relative_path, line, col)
        token = current_token(relative_path, line, col)

        return [] if token.content.nil?
        return [] unless (variable_lookup = VariableLookupFinder.lookup(token))

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
        object = find_object_from_variable_lookup(variable_lookup)
        property = nil

        variable_lookup.lookups.each do |name|
          object
            &.properties
            &.find { |prop| prop.name == name }
            &.tap do |prop|
              if prop
                property = prop
                object = find_object(prop.return_type)
              end
            end
        end

        [object, property]
      end

      def find_object_from_variable_lookup(variable_lookup)
        # Objects like 'product' are a complex structure with fields and their
        # return type is no present.
        object = find_object(variable_lookup.name)

        # However, we also handle objects that have simple built-in types, like
        # 'current_tags', which is an 'array'.
        object = find_object(object.return_type) while object&.return_type
        object
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

      def find_object(object_name)
        ShopifyLiquid::SourceIndex
          .objects
          .find { |entry| entry.name == object_name }
      end
    end
  end
end
