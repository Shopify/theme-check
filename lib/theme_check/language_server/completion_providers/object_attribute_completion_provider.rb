# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectAttributeCompletionProvider < CompletionProvider
      def completions(content, cursor)
        return [] unless (variable_lookup = variable_lookup_at_cursor(content, cursor))
        return [] if variable_lookup.lookups.size >= 1 && content[cursor - 1] == "."
        attributes_for_variable_lookup(variable_lookup)
          .select { |w| w.starts_with?(partial(variable_lookup)) }
          .map { |property| attribute_to_completion(property) }
      end

      private

      def variable_lookup_at_cursor(content, cursor)
        VariableLookupFinder.lookup(content, cursor)
      end

      def partial(variable_lookup)
        variable_lookup.lookups.last || ''
      end

      def attributes_for_variable_lookup(variable_lookup)
        return [] unless variable_lookup.lookups.size <= 1
        attributes_for_label(variable_lookup.name) || []
      end

      def attributes_for_label(label)
        ShopifyLiquid::Object.attributes_by_label[label] || []
      end

      def attribute_to_completion(object)
        {
          label: object,
          kind: CompletionItemKinds::VARIABLE,
        }
      end
    end
  end
end
