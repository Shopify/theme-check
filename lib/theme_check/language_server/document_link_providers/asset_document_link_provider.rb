# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssetDocumentLinkProvider < DocumentLinkProvider
      def document_links(buffer)
        matches(buffer, ASSET_INCLUDE).map do |match|
          start_line, start_character = from_index_to_row_column(
            buffer,
            match.begin(:partial),
          )

          end_line, end_character = from_index_to_row_column(
            buffer,
            match.end(:partial)
          )

          {
            target: asset_link(match[:partial]),
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

      def asset_link(partial)
        file_link('assets', partial, '')
      end
    end
  end
end
