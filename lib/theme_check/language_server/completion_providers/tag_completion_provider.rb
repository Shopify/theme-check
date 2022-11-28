# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class TagCompletionProvider < CompletionProvider
      def completions(context)
        content = context.content
        cursor = context.cursor

        return [] if content.nil?
        return [] unless can_complete?(content, cursor)
        partial = first_word(content) || ''
        labels = ShopifyLiquid::Tag.labels
        labels += ShopifyLiquid::Tag.end_labels
        labels
          .select { |w| w.start_with?(partial) }
          .map { |tag| tag_to_completion(tag) }
      end

      def can_complete?(content, cursor)
        content.start_with?(Liquid::TagStart) && (
          cursor_on_first_word?(content, cursor) ||
          cursor_on_start_content?(content, cursor, Liquid::TagStart)
        )
      end

      private

      def tag_to_completion(tag)
        content = ShopifyLiquid::Documentation.tag_doc(tag)

        {
          label: tag,
          kind: CompletionItemKinds::KEYWORD,
          **doc_hash(content),
        }
      end
    end
  end
end
