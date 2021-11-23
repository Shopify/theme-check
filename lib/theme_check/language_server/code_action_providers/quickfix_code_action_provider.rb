# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class QuickfixCodeActionProvider < CodeActionProvider
      kind "quickfix"

      def code_actions(relative_path, range)
        correctable_diagnostics = diagnostics_manager
          .diagnostics(relative_path)
          .filter(&:correctable?)
          .reject do |diagnostic|
            # We cannot quickfix if the buffer was modified. This means
            # our diagnostics and InMemoryStorage are out of sync.
            diagnostic.file_version != storage.version(diagnostic.relative_path)
          end

        diagnostics_under_cursor = correctable_diagnostics
          .filter { |diagnostic| diagnostic.offense.in_range?(range) }

        return [] if diagnostics_under_cursor.empty?

        (
          quickfix_cursor_code_actions(diagnostics_under_cursor) +
          quickfix_all_of_type_code_actions(diagnostics_under_cursor, correctable_diagnostics) +
          quickfix_all_code_action(correctable_diagnostics)
        )
      end

      private

      def quickfix_cursor_code_actions(diagnostics)
        diagnostics.map do |diagnostic|
          {
            title: "Fix this #{diagnostic.code} problem: #{diagnostic.message}",
            kind: kind,
            diagnostics: [diagnostic.to_h],
            isPreferred: true,
            command: {
              title: 'quickfix',
              command: CorrectionExecuteCommandProvider.command,
              arguments: [diagnostic.to_h],
            },
          }
        end
      end

      def quickfix_all_of_type_code_actions(cursor_diagnostics, correctable_diagnostics)
        codes = Set.new(cursor_diagnostics.map(&:code))
        correctable_diagnostics_by_code = correctable_diagnostics.group_by(&:code)
        codes.flat_map do |code|
          diagnostics = correctable_diagnostics_by_code[code].map(&:to_h)
          return [] unless diagnostics.size > 1
          {
            title: "Fix all #{code} problems",
            kind: kind,
            diagnostics: diagnostics,
            command: {
              title: 'quickfix',
              command: CorrectionExecuteCommandProvider.command,
              arguments: diagnostics,
            },
          }
        end
      end

      def quickfix_all_code_action(diagnostics)
        return [] unless diagnostics.size > 1
        diagnostics = diagnostics.map(&:to_h)
        [{
          title: "Fix all auto-fixable problems",
          kind: kind,
          diagnostics: diagnostics,
          command: {
            title: 'quickfix',
            command: CorrectionExecuteCommandProvider.command,
            arguments: diagnostics,
          },
        }]
      end
    end
  end
end
