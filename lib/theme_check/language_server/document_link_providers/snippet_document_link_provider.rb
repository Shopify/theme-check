# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class SnippetDocumentLinkProvider < DocumentLinkProvider
      def document_links(buffer)
        [PARTIAL_RENDER, PARTIAL_INCLUDE].flat_map do |regexp|
          matches(buffer, regexp).map do |match|
            start_line, start_character = from_index_to_row_column(
              buffer,
              match.begin(:partial),
            )

            end_line, end_character = from_index_to_row_column(
              buffer,
              match.end(:partial)
            )

            {
              target: snippet_link(match[:partial]),
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
      end

      def snippet_link(partial)
        file_link('snippets', partial, '.liquid')
      end
    end
  end
end
