# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProvider < CodeActionProvider
      include CodeActionHelper

      kind "quickfix"

      def code_actions(absolute_path, range)
        diagnostics_tracker.diagnostics(absolute_path)
          .filter { |diagnostic| diagnostic.correctable? && offense_in_range?(diagnostic.offense, range) }
          .reject do |diagnostic|
            # We cannot quickfix if the buffer was modified. This means
            # our diagnostics and InMemoryStorage are out of sync.
            diagnostic.data[:version] != storage.latest_version(diagnostic.data[:relative_path])
          end
          .map { |diagnostic| diagnostic_to_code_action(diagnostic) }
      end

      private

      # @param offense [ThemeCheck::LanguageServer::Diagnostic]
      def diagnostic_to_code_action(diagnostic)
        {
          title: "Correct #{diagnostic.message}",
          kind: kind,
          diagnostics: [diagnostic.to_h],
          command: {
            title: 'quickfix',
            command: LanguageServer::CorrectionExecuteCommandProvider.command,
            arguments: [diagnostic.to_h],
          },
        }
      end
    end
  end
end
