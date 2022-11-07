# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionProvider
      include CompletionHelper
      include PositionHelper
      include RegexHelpers

      attr_reader :storage

      CurrentToken = Struct.new(:content, :cursor, :absolute_cursor, :buffer)

      class << self
        def all
          @all ||= []
        end

        def inherited(subclass)
          all << subclass
        end
      end

      def initialize(storage = InMemoryStorage.new)
        @storage = storage
      end

      def completions(relative_path, line, col)
        raise NotImplementedError
      end

      def current_token(relative_path, line, col)
        buffer = read_file(relative_path)
        absolute_cursor = from_row_column_to_index(buffer, line, col)
        token = find_token(buffer, absolute_cursor)

        return [] if token.nil?

        content = token.content
        cursor = absolute_cursor - token.start

        CurrentToken.new(content, cursor, absolute_cursor, buffer)
      end

      def read_file(relative_path)
        storage.read(relative_path)
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

      def doc_hash(content)
        return {} if content.nil? || content.empty?

        {
          documentation: {
            kind: MarkupKinds::MARKDOWN,
            value: content,
          },
        }
      end
    end
  end
end
