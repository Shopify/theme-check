# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CorrectionExecuteCommandProvider < ExecuteCommandProvider
      command "correction"

      def execute(diagnostics)
        changes = diagnostics
          .group_by { |d| d.dig("data", "uri") }
          .transform_values do |diagnostics_for_uri|
            diagnostics_for_uri.flat_map do |diagnostic|
              to_text_edit(diagnostic)
            end
          end
        result = bridge.send_request('workspace/applyEdit', {
          label: 'Theme Check correction',
          edit: {
            changes: changes,
          },
        })
        return unless result['applied']
        # Clean up DiagnosticsTracker
      end

      def to_text_edit(diagnostic)
        corrector = TextEditCorrector.new
        offense = diagnostics_tracker
          .single_file_offenses(diagnostic.dig('data', 'path'))
          .find { |o| JSON.parse(JSON.generate(o.to_diagnostic)) == diagnostic }
        return [] if offense.nil?
        offense.correct(corrector)
        corrector.edits
      end
    end
  end
end
