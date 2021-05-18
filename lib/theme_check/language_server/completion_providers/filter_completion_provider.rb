# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class FilterCompletionProvider < CompletionProvider
      NAMED_FILTER = /#{Liquid::FilterSeparator}\s*(\w+)/o

      def completions(content, cursor)
        return [] unless can_complete?(content, cursor)
        available_labels
          .select { |w| w.start_with?(partial(content, cursor)) }
          .map { |filter| filter_to_completion(filter) }
      end

      def can_complete?(content, cursor)
        content.match?(Liquid::FilterSeparator) && (
          cursor_on_start_content?(content, cursor, Liquid::FilterSeparator) ||
          cursor_on_filter?(content, cursor)
        )
      end

      private

      def available_labels
        @labels ||= ShopifyLiquid::Filter.labels - ShopifyLiquid::DeprecatedFilter.labels
      end

      def cursor_on_filter?(content, cursor)
        return false unless content.match?(NAMED_FILTER)
        matches(content, NAMED_FILTER).any? do |match|
          match.begin(1) <= cursor && cursor < match.end(1) + 1 # including next character
        end
      end

      def partial(content, cursor)
        return '' unless content.match?(NAMED_FILTER)
        partial_match = matches(content, NAMED_FILTER).find do |match|
          match.begin(1) <= cursor && cursor < match.end(1) + 1 # including next character
        end
        return '' if partial_match.nil?
        partial_match[1]
      end

      def filter_to_completion(filter)
        {
          label: filter,
          kind: CompletionItemKinds::FUNCTION,
        }
      end
    end
  end
end
