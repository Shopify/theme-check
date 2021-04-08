# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectCompletionProvider < CompletionProvider
      def completions(content, cursor)
        return [] unless (variable_lookup = variable_lookup_at_cursor(content, cursor))
        return [] unless variable_lookup.lookups.empty?
        return [] if content[cursor - 1] == "."
        ShopifyLiquid::Object.labels
          .select { |w| w.start_with?(partial(variable_lookup)) }
          .map { |object| object_to_completion(object) }
      end

      def variable_lookup_at_cursor(content, cursor)
        VariableLookupFinder.lookup(content, cursor)
      end

      def partial(variable_lookup)
        variable_lookup.name || ''
      end

      private

      def object_to_completion(object)
        {
          label: object,
          kind: CompletionItemKinds::VARIABLE,
        }
      end
    end
  end
end
