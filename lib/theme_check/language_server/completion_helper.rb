# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module CompletionHelper
      WORD = /\w+/

      def cursor_on_start_content?(content, cursor, regex)
        content.slice(0, cursor).match?(/#{regex}(?:\s|\n)*$/m)
      end

      def cursor_on_first_word?(content, cursor)
        word = content.match(WORD)
        return false if word.nil?
        word_start = word.begin(0)
        word_end = word.end(0)
        word_start <= cursor && cursor <= word_end
      end

      def first_word(content)
        return content.match(WORD)[0] if content.match?(WORD)
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
