# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ObjectCompletionProvider < CompletionProvider
      def completions(content, cursor)
        return [] unless can_complete?(content, cursor)
        partial = first_word(content) || ''
        ShopifyLiquid::Object.labels
          .select { |w| w.starts_with?(partial) }
          .map { |object| object_to_completion(object) }
      end

      def can_complete?(content, cursor)
        content.match?(Liquid::VariableStart) && (
          cursor_on_first_word?(content, cursor) ||
          cursor_on_start_content?(content, cursor, Liquid::VariableStart)
        )
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
