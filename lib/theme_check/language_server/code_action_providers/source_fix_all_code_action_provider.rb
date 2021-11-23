# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class SourceFixAllCodeActionProvider < CodeActionProvider
      kind "source.fixAll"

      def code_actions(relative_path, _)
        diagnostics = diagnostics_manager
          .diagnostics(relative_path)
          .filter(&:correctable?)
          .reject do |diagnostic|
            # We cannot quickfix if the buffer was modified. This means
            # our diagnostics and InMemoryStorage are out of sync.
            diagnostic.file_version != storage.version(diagnostic.relative_path)
          end
          .map(&:to_h)
        diagnostics_to_code_action(diagnostics)
      end

      private

      def diagnostics_to_code_action(diagnostics)
        return [] if diagnostics.empty?
        [
          {
            title: "Fix all Theme Check auto-fixable problems",
            kind: kind,
            diagnostics: diagnostics,
            command: {
              title: 'fixAll.file',
              command: LanguageServer::CorrectionExecuteCommandProvider.command,
              arguments: diagnostics,
            },
          },
        ]
      end
    end
  end
end
