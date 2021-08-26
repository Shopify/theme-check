# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class AssetDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = ASSET_INCLUDE
      @destination_directory = "assets"
      @destination_postfix = ""
    end
  end
end
