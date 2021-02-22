# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionEngine
      include PositionHelper
      WORD = /\w+/
      NAMED_FILTER = /#{Liquid::FilterSeparator}\s*(\w+)/o

      def initialize(storage)
        @storage = storage
      end

      def completions(name, line, col)
        token = find_token(name, line, col)
        return [] if token.nil?

        cursor = cursor_index(token, line, col)
        content = token.content
        if tag_completion?(content, cursor)
          tag_completions(content)
        elsif object_completion?(content, cursor)
          object_completions(content)
        elsif filter_completion?(content, cursor)
          filter_completions(content, cursor)
        else
          []
        end
      end

      def find_token(name, line, col)
        template = @storage.read(name)
        Tokens.new(template).find do |token|
          # it's easier to make a condition for is it out than is it in.
          is_out_of_bounds = (
            line < token.start_line ||
            token.end_line < line ||
            (token.start_line == line && col < token.start_col) ||
            (token.end_line == line && token.end_col < col)
          )

          !is_out_of_bounds
        end
      end

      private

      def cursor_index(token, line, col)
        relative_line = line - token.start_line
        return col - token.start_col if relative_line == 0
        from_line_to_column(relative_line, col, token.content)
      end

      def cursor_on_first_word?(content, cursor)
        word = content.match(WORD)
        return false if word.nil?
        word_start = word.begin(0)
        word_end = word.end(0)
        word_start <= cursor && cursor <= word_end
      end

      def cursor_on_start_content?(content, cursor, regex)
        content.slice(0, cursor).match?(/^#{regex}(?:\s|\n)*$/m)
      end

      def first_word(content)
        return content.match(WORD)[0] if content.match?(WORD)
      end

      def tag_completion?(content, cursor)
        content.starts_with?(Liquid::TagStart) && (
          cursor_on_first_word?(content, cursor) ||
          cursor_on_start_content?(content, cursor, Liquid::TagStart)
        )
      end

      def tag_completions(token)
        partial = first_word(token) || ''
        ShopifyLiquid::Tag.labels
          .select { |w| w.starts_with?(partial) }
          .map { |tag| tag_to_completion(tag) }
      end

      def tag_to_completion(tag)
        {
          label: tag,
          kind: CompletionItemKinds::KEYWORD,
        }
      end

      def object_completion?(content, cursor)
        content.match?(Liquid::VariableStart) && (
          cursor_on_first_word?(content, cursor) ||
          cursor_on_start_content?(content, cursor, Liquid::VariableStart)
        )
      end

      def object_completions(content)
        partial = first_word(content) || ''
        ShopifyLiquid::Object.labels
          .select { |w| w.starts_with?(partial) }
          .map { |object| object_to_completion(object) }
      end

      def object_to_completion(tag)
        {
          label: tag,
          kind: CompletionItemKinds::VARIABLE,
        }
      end







      def matches(s, re)
        start_at = 0
        matches = []
        while(m = s.match(re, start_at))
          matches.push(m)
          start_at = m.end(0)
        end
        matches
      end
    end
  end
end
