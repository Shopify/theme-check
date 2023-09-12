# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkProvider
      include RegexHelpers
      include PositionHelper
      include URIHelper

      class << self
        attr_accessor :partial_regexp, :destination_directory, :destination_postfix

        def all
          @all ||= []
        end

        def inherited(subclass)
          all << subclass
        end
      end

      def partial_regexp
        self.class.partial_regexp
      end

      def destination_directory
        self.class.destination_directory
      end

      def destination_postfix
        self.class.destination_postfix
      end

      def document_links(buffer, storage)
        matches(buffer, partial_regexp).map do |match|
          start_row, start_column = from_index_to_row_column(
            buffer,
            match.begin(:partial),
          )

          end_row, end_column = from_index_to_row_column(
            buffer,
            match.end(:partial)
          )

          partial = match[:partial]
          uri = storage.path(destination_directory + '/' + partial + destination_postfix)

          {
            target: uri,
            range: {
              start: {
                line: start_row,
                character: start_column,
              },
              end: {
                line: end_row,
                character: end_column,
              },
            },
          }
        end
      end
    end
  end
end
