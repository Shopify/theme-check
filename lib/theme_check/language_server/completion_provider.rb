# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionProvider
      include CompletionHelper
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

      def doc_hash(content)
        return {} if content.nil? || content.empty?

        {
          documentation: {
            kind: MarkupKinds::MARKDOWN,
            value: content,
          },
        }
      end

      def format_hash(entry)
        return {} unless entry
        return { sortText: entry.name } unless entry.deprecated?

        {
          tags: [CompletionItemTag::DEPRECATED],
          sortText: "~#{entry.name}",
        }
      end
    end
  end
end
