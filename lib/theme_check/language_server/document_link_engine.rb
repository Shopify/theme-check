# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkEngine
      include PositionHelper
      include RegexHelpers

      def initialize(storage)
        @storage = storage
      end

      def document_links(uri)
        buffer = @storage.read(uri)
        matches(buffer, PARTIAL_RENDER).map do |match|
          start_line, start_character = from_index_to_line_column(
            buffer,
            match.begin(:partial),
          )

          end_line, end_character = from_index_to_line_column(
            buffer,
            match.end(:partial)
          )

          {
            target: link(match[:partial]),
            range: {
              start: {
                line: start_line,
                character: start_character,
              },
              end: {
                line: end_line,
                character: end_character,
              },
            },
          }
        end
      end

      def link(partial)
        'file://' + @storage.path('snippets/' + partial + '.liquid')
      end
    end
  end
end
