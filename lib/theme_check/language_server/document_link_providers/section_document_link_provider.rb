# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class SectionDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = PARTIAL_SECTION
      @destination_directory = "sections"
      @destination_postfix = ".liquid"
    end
  end
end
