# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class IncludeDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = PARTIAL_INCLUDE
      @destination_directory = "partials"
      @destination_postfix = ".liquid"
    end
  end
end
