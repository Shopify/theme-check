# frozen_string_literal: true

module PlatformosCheck
  module LanguageServer
    class SectionDocumentLinkProvider < DocumentLinkProvider
      @partial_regexp = PARTIAL_SECTION
      @destination_directory = "sections"
      @destination_postfix = ".liquid"
    end
  end
end
