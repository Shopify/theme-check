# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CorrectionExecuteCommandProvider < ExecuteCommandProvider
      command "correction"

      # The arguments passed to this method are the ones forwarded
      # from the selected CodeAction by the client.
      #
      # @param diagnostic_hashes [Array] - of diagnostics
      def execute(diagnostic_hashes)
        document_changes = diagnostic_hashes
          .group_by { |d| to_text_document(d) }
          .map do |text_document, diagnostic_hashes_for_uri|
            {
              textDocument: text_document,
              edits: diagnostic_hashes_for_uri.flat_map do |diagnostic_hash|
                to_text_edit(diagnostic_hash)
              end,
            }
          end
        result = bridge.send_request('workspace/applyEdit', {
          label: 'Theme Check correction',
          edit: {
            documentChanges: document_changes,
          },
        })
        return unless result['applied']

        # Clean up fixed diagnostics from the list.
        diagnostic_hashes.each do |diagnostic|
          diagnostics_tracker.delete(diagnostic.dig(:data, :path), diagnostic)
        end
      end

      private

      def to_text_document(diagnostic_hash)
        {
          uri: diagnostic_hash.dig(:data, :uri),
          version: diagnostic_hash.dig(:data, :version),
        }
      end

      def to_text_edit(diagnostic_hash)
        corrector = TextEditCorrector.new
        offense = diagnostics_tracker
          .diagnostics(diagnostic_hash.dig(:data, :path))
          .find { |d| d == diagnostic_hash }
          &.offense
        return [] if offense.nil?
        offense.correct(corrector)
        corrector.edits
      end
    end
  end
end
