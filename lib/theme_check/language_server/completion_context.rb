# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionContext
      include PositionHelper

      attr_reader :storage, :relative_path, :line, :col

      def initialize(storage, relative_path, line, col)
        @storage = storage
        @relative_path = relative_path
        @line = line
        @col = col
      end

      def buffer
        @buffer ||= storage.read(relative_path)
      end

      def buffer_until_previous_row
        @buffer_without_current_row ||= buffer[0..absolute_cursor].lines[0...-1].join
      end

      def absolute_cursor
        @absolute_cursor ||= from_row_column_to_index(buffer, line, col)
      end

      def cursor
        @cursor ||= absolute_cursor - token&.start || 0
      end

      def content
        @content ||= token&.content
      end

      def token
        @token ||= Tokens.new(buffer).find do |t|
          # Here we include the next character and exclude the first
          # one becase when we want to autocomplete inside a token
          # and at most 1 outside it since the cursor could be placed
          # at the end of the token.
          t.start < absolute_cursor && absolute_cursor <= t.end
        end
      end

      def clone_and_overwrite(col:)
        CompletionContext.new(storage, relative_path, line, col)
      end
    end
  end
end
