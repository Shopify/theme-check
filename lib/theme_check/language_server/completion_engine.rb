# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionEngine
      include PositionHelper

      def initialize(storage)
        @storage = storage
        @providers = CompletionProvider.all.map(&:new)
      end

      def completions(name, line, col)
        token = find_token(name, line, col)
        return [] if token.nil?

        cursor = cursor_index(token, line, col)
        @providers.flat_map { |p| p.completions(token.content, cursor) }
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
        from_line_column_to_index(relative_line, col, token.content)
      end
    end
  end
end
