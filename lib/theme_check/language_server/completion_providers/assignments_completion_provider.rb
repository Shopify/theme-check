# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssignmentsCompletionProvider < CompletionProvider
      def completions(context)
        content = context.buffer[0..context.absolute_cursor].lines[0...-1].join

        return [] if content.nil?
        return [] unless (variable_lookup = VariableLookupFinder.lookup(context))
        return [] unless variable_lookup.lookups.empty?
        return [] if context.content[context.cursor - 1] == "."

        finder = VariableLookupFinder::AssignmentsFinder.new(content)
        finder.find!

        finder.assignments.map do |label, potential_lookup|
          object, _property = VariableLookupTraverser.lookup_object_and_property(potential_lookup)
          object_to_completion(label, object.name)
        end
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
    end
  end
end
