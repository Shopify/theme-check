# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Configuration
      CHECK_ON_OPEN = :"themeCheck.checkOnOpen"
      CHECK_ON_SAVE = :"themeCheck.checkOnSave"
      CHECK_ON_CHANGE = :"themeCheck.checkOnChange"

      def initialize(bridge, capabilities)
        @bridge = bridge
        @capabilities = capabilities
        @mutex = Mutex.new
        @initialized = false
        @config = {
          CHECK_ON_OPEN => @capabilities.initialization_option(CHECK_ON_OPEN) || true,
          CHECK_ON_SAVE => @capabilities.initialization_option(CHECK_ON_SAVE) || true,
          CHECK_ON_CHANGE => @capabilities.initialization_option(CHECK_ON_CHANGE) || true,
        }
      end

      def fetch(force: nil)
        @mutex.synchronize do
          return unless @capabilities.supports_workspace_configuration?
          return if initialized? && !force
          check_on_open, check_on_save, check_on_change = @bridge.send_request(
            "workspace/configuration",
            items: [
              { section: CHECK_ON_OPEN },
              { section: CHECK_ON_SAVE },
              { section: CHECK_ON_CHANGE },
            ],
          )
          @config[CHECK_ON_OPEN] = check_on_open unless check_on_open.nil?
          @config[CHECK_ON_CHANGE] = check_on_change unless check_on_change.nil?
          @config[CHECK_ON_SAVE] = check_on_save unless check_on_save.nil?
          @initialized = true
        end
      end

      def register_did_change_capability
        return unless @capabilities.supports_workspace_did_change_configuration_dynamic_registration?
        @bridge.send_request('client/registerCapability', registrations: [{
          id: "workspace/didChangeConfiguration",
          method: "workspace/didChangeConfiguration",
        }])
      end

      def initialized?
        @initialized
      end

      def check_on_open?
        fetch # making sure we have an initialized value
        @config[CHECK_ON_OPEN]
      end

      def check_on_save?
        fetch # making sure we have for an initialized value
        @config[CHECK_ON_SAVE]
      end

      def check_on_change?
        fetch # making sure we have for an initialized value
        @config[CHECK_ON_CHANGE]
      end
    end
  end
end
