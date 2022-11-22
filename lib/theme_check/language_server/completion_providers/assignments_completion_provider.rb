# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssignmentsCompletionProvider < CompletionProvider
      def completions(context)
        content = context.content

        return [] if content.nil?
        return [] if content[context.cursor - 1] == "."

        finder = VariableLookupFinder::AssignmentsFinder.new(content)
        finder.find!
        finder.assignments.map { |label, value| object_to_completion(label, value.name) }
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
