# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CorrectionExecuteCommandProvider < ExecuteCommandProvider
      include URIHelper

      command "correction"

      attr_reader :storage, :bridge, :diagnostics_manager

      def initialize(storage, bridge, diagnostics_manager)
        @storage = storage
        @bridge = bridge
        @diagnostics_manager = diagnostics_manager
      end

      # The arguments passed to this method are the ones forwarded
      # from the selected CodeAction by the client.
      #
      # @param diagnostic_hashes [Array] - of diagnostics
      def execute(diagnostic_hashes)
        # attempt to apply the document changes
        workspace_edit = diagnostics_manager.workspace_edit(diagnostic_hashes)
        result = bridge.send_request('workspace/applyEdit', {
          label: 'Theme Check correction',
          edit: workspace_edit,
        })

        # Bail if unable to apply changes
        return unless result[:applied]

        # Clean up internal representation of fixed diagnostics
        diagnostics_update = diagnostics_manager.delete_applied(diagnostic_hashes)

        # Send updated diagnostics to client
        diagnostics_update
          .map do |relative_path, diagnostics|
            bridge.send_notification('textDocument/publishDiagnostics', {
              uri: file_uri(storage.path(relative_path)),
              diagnostics: diagnostics.map(&:to_h),
            })
            storage.path(relative_path)
          end
      end
    end
  end
end
