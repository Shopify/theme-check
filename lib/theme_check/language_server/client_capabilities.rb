# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ClientCapabilities
      def initialize(capabilities)
        @capabilities = capabilities
      end

      def supports_work_done_progress?
        @capabilities.dig(:window, :workDoneProgress) || false
      end
    end
  end
end
