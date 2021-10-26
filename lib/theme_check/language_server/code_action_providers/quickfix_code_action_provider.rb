# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProvider < CodeActionProvider
      include CodeActionHelper

      kind "quickfix"

      def code_actions(absolute_path, range)
        diagnostics_tracker.diagnostics(absolute_path)
          .map(&:offense)
          .filter { |offense| offense.correctable? && offense_in_range?(offense, range) }
          .map { |offense| offense_to_code_action(offense) }
      end

      private

      # @param offense [ThemeCheck::Offense]
      def offense_to_code_action(offense)
        diagnostic = Diagnostic.new(offense).to_h
        {
          title: "Correct #{offense.message}",
          kind: kind,
          diagnostics: [diagnostic],
          command: {
            title: 'quickfix',
            command: LanguageServer::CorrectionExecuteCommandProvider.command,
            arguments: [diagnostic],
          },
        }
      end
    end
  end
end
