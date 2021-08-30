# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkEngine
      def initialize(storage)
        @storage = storage
        @providers = DocumentLinkProvider.all.map { |x| x.new(storage) }
      end

      def document_links(relative_path)
        buffer = @storage.read(relative_path)
        return [] unless buffer
        @providers.flat_map do |p|
          p.document_links(buffer)
        end
      end
    end
  end
end
