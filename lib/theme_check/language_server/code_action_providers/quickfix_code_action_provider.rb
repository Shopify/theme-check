# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProvider < CodeActionProvider
      include CodeActionHelper

      kind "quickfix"

      def code_actions(absolute_path, range)
        diagnostics_tracker.single_file_offenses(absolute_path)
          .filter { |offense| offense.correctable? && offense_in_range?(offense, range) }
          .map { |offense| offense_to_code_action(offense) }
      end

      private

      # @param offense [ThemeCheck::Offense]
      def offense_to_code_action(offense)
        {
          title: "Correct #{offense.message}",
          kind: kind,
          diagnostics: [offense.to_diagnostic],
          command: {
            title: 'quickfix',
            command: LanguageServer::CorrectionExecuteCommandProvider.command,
            arguments: [offense.to_diagnostic],
          },
        }
      end
    end
  end
end
