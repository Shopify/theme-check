# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class SourceFixAllCodeActionProvider < CodeActionProvider
      kind "source.fixAll"

      def code_actions(relative_path, range)
        []
      end
    end
  end
end
