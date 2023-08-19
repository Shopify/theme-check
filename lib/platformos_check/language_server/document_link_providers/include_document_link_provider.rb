# frozen_string_literal: true

module PlatformosCheck
  module LanguageServer
    class IncludeDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = PARTIAL_INCLUDE
      @destination_directory = "snippets"
      @destination_postfix = ".liquid"
    end
  end
end
