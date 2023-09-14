# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssetDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = ASSET_INCLUDE
      @destination_directory = "assets"
      @destination_postfix = ""

      def self.find_variation(relative_path, storage)
        return "#{relative_path}.liquid" if storage.read("#{relative_path}.liquid")
        relative_path
      end
    end
  end
end
