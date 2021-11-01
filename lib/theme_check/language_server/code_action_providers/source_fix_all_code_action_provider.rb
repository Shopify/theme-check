# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class SourceFixAllCodeActionProvider < CodeActionProvider
      kind "source.fixAll"

      def code_actions(absolute_path, _)
        diagnostics = diagnostics_manager
          .diagnostics(absolute_path)
          .filter(&:correctable?)
          .map(&:to_h)
        diagnostics_to_code_action(diagnostics)
      end

      private

      def diagnostics_to_code_action(diagnostics)
        return [] if diagnostics.empty?
        [
          {
            title: "Fix all correctable checks",
            kind: kind,
            diagnostics: diagnostics,
            command: {
              title: 'fixAll',
              command: LanguageServer::CorrectionExecuteCommandProvider.command,
              arguments: diagnostics,
            },
          },
        ]
      end
    end
  end
end
