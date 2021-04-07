# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class TagCompletionProvider < CompletionProvider
      def completions(content, cursor)
        return [] unless can_complete?(content, cursor)
        partial = first_word(content) || ''
        labels = ShopifyLiquid::Tag.labels
        labels += ShopifyLiquid::Tag.end_labels if partial.starts_with?('end')
        labels
          .select { |w| w.starts_with?(partial) }
          .map { |tag| tag_to_completion(tag) }
      end

      def can_complete?(content, cursor)
        content.starts_with?(Liquid::TagStart) && (
          cursor_on_first_word?(content, cursor) ||
          cursor_on_start_content?(content, cursor, Liquid::TagStart)
        )
      end

      private

      def tag_to_completion(tag)
        {
          label: tag,
          kind: CompletionItemKinds::KEYWORD,
        }
      end
    end
  end
end
