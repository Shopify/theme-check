# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class IncludeComponentDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = COMPONENT_INCLUDE
      @destination_directory = "components"
      @destination_postfix = ".liquid"
    end
  end
end
