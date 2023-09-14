# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class RenderComponentDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = COMPONENT_RENDER
      @destination_directory = "components"
      @destination_postfix = ".liquid"
    end
  end
end
