# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssignmentsCompletionProvider < CompletionProvider
      def completions(context)
        content = context.buffer_until_previous_row

        return [] if content.nil?
        return [] unless (variable_lookup = VariableLookupFinder.lookup(context))
        return [] unless variable_lookup.lookups.empty?
        return [] if context.content[context.cursor - 1] == "."

        finder = VariableLookupFinder::AssignmentsFinder.new(content)
        finder.find!
        finder
          .assignments
          .map { |label, potential_lookup| object_to_completion(label, object_name(potential_lookup)) }
          .compact
      end

      private

      def object_to_completion(label, object)
        content = ShopifyLiquid::Documentation.object_doc(object)

        {
          label: label,
          kind: CompletionItemKinds::VARIABLE,
          **doc_hash(content),
        }
      end

      def object_name(potential_lookup)
        object, _property = VariableLookupTraverser.lookup_object_and_property(potential_lookup)
        object&.name
      end
    end
  end
end
