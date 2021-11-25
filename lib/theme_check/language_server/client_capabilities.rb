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

      def supports_workspace_configuration?
        @capabilities.dig(:workspace, :configuration) || false
      end

      def supports_workspace_did_change_configuration_dynamic_registration?
        @capabilities.dig(:workspace, :didChangeConfiguration, :dynamicRegistration) || false
      end

      def initialization_option(key)
        @capabilities.dig(:initializationOptions, key)
      end
    end
  end
end
