# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class RenderDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = PARTIAL_RENDER
      @destination_directory = "partials"
      @destination_postfix = ".liquid"
    end
  end
end
