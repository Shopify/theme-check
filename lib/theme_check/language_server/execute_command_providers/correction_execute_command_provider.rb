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
        # compile all the document changes
        document_changes = diagnostic_hashes
          .group_by { |d| to_text_document(d) }
          .map do |text_document, diagnostic_hashes_for_document|
            {
              textDocument: text_document,
              edits: diagnostic_hashes_for_document.flat_map do |diagnostic_hash|
                to_text_edit(diagnostic_hash)
              end,
            }
          end

        # attempt to apply the document changes
        result = bridge.send_request('workspace/applyEdit', {
          label: 'Theme Check correction',
          edit: {
            documentChanges: document_changes,
          },
        })

        return unless result[:applied]

        # Clean up fixed diagnostics from the list.
        diagnostic_hashes.each do |diagnostic_hash|
          absolute_path = diagnostic_hash.dig(:data, :path)
          diagnostic = diagnostics_tracker
            .diagnostics(absolute_path)
            .find { |d| d == diagnostic_hash }
          diagnostics_tracker
            .delete(absolute_path, diagnostic)
        end

        # Send updated diagnostics to client
        diagnostic_hashes
          .group_by { |d| d.dig(:data) }
          .map do |data, _|
            bridge.send_notification('textDocument/publishDiagnostics', {
              uri: data[:uri],
              diagnostics: diagnostics_tracker.diagnostics(data[:path]).map(&:to_h),
            })
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
