# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionEngine
      include PositionHelper

      def initialize(storage)
        @storage = storage
        @providers = CompletionProvider.all.map { |x| x.new(storage) }
      end

      def completions(relative_path, line, col)
        buffer = @storage.read(relative_path)
        cursor = from_row_column_to_index(buffer, line, col)
        token = find_token(buffer, cursor)
        return [] if token.nil?

        @providers.flat_map do |p|
          p.completions(
            token.content,
            cursor - token.start
          )
        end
      end

      def find_token(buffer, cursor)
        Tokens.new(buffer).find do |token|
          # Here we include the next character and exclude the first
          # one becase when we want to autocomplete inside a token
          # and at most 1 outside it since the cursor could be placed
          # at the end of the token.
          token.start < cursor && cursor <= token.end
        end
      end
    end
  end
end
