# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectCompletionProvider < CompletionProvider
      def completions(context)
        content = context.content

        return [] if content.nil?
        return [] unless (variable_lookup = VariableLookupFinder.lookup(context))
        return [] unless variable_lookup.lookups.empty?
        return [] if content[context.cursor - 1] == "."

        ShopifyLiquid::Object.labels
          .select { |w| w.start_with?(partial(variable_lookup)) }
          .map { |object| object_to_completion(object) }
      end

      def partial(variable_lookup)
        variable_lookup.name || ''
      end

      private

      def object_to_completion(object)
        content = ShopifyLiquid::Documentation.object_doc(object)

        {
          label: object,
          kind: CompletionItemKinds::VARIABLE,
          **doc_hash(content),
        }
      end
    end
  end
end
