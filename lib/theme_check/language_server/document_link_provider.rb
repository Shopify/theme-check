# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkProvider
      include RegexHelpers
      include PositionHelper

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

      def document_links(buffer)
        raise NotImplementedError
      end

      def file_link(directory, partial, extension)
        "file://#{@storage.path(directory + '/' + partial + extension)}"
      end
    end
  end
end
