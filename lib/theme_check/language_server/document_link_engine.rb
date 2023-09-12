# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentLinkEngine
      def initialize(workspace)
        @workspace = workspace
        @providers = DocumentLinkProvider.all.map { |x| x.new }
      end

      def document_links(relative_path)
        buffer = @workspace.read(relative_path)
        storage = @workspace.theme_view(relative_path)
        return [] unless buffer && storage
        @providers.flat_map do |p|
          p.document_links(buffer, storage)
        end
      end
    end
  end
end
