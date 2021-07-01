# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkEngine
      include PositionHelper
      include RegexHelpers

      def initialize(storage)
        @storage = storage
      end

      def document_links(relative_path)
        buffer = @storage.read(relative_path)
        return [] unless buffer
        snippet_matches = matches(buffer, PARTIAL_RENDER).map do |match|
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
        asset_matches = matches(buffer, ASSET_INCLUDE).map do |match|
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
        snippet_matches + asset_matches
      end

      def snippet_link(partial)
        file_link('snippets', partial, '.liquid')
      end

      def asset_link(partial)
        file_link('assets', partial, '')
      end

      private

      def file_link(directory, partial, extension)
        "file://#{@storage.path(directory + '/' + partial + extension)}"
      end
    end
  end
end
