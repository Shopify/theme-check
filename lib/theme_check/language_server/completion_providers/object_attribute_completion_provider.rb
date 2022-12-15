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
        object, property = VariableLookupTraverser.lookup_object_and_property(variable_lookup)

        # If the last lookup level is incomplete/invalid, use the partial term
        # to filter object properties.
        partial = partial_property_name(property, variable_lookup)

        return [] unless object

        object
          .properties
          .select { |prop| partial.nil? || prop.name.start_with?(partial) }
          .map { |prop| property_to_completion(prop) }
      end

      private

      def partial_property_name(property, variable_lookup)
        last_property = variable_lookup.lookups.last
        last_property if last_property != property&.name
      end

      def property_to_completion(prop)
        content = ShopifyLiquid::Documentation.render_doc(prop)

        {
          label: prop.name,
          kind: CompletionItemKinds::PROPERTY,
          **format_hash(prop),
          **doc_hash(content),
        }
      end
    end
  end
end
