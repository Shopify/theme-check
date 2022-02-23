# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Configuration
      CHECK_ON_OPEN = :"themeCheck.checkOnOpen"
      CHECK_ON_SAVE = :"themeCheck.checkOnSave"
      CHECK_ON_CHANGE = :"themeCheck.checkOnChange"
      ONLY_SINGLE_FILE = :"themeCheck.onlySingleFileChecks"

      def initialize(bridge, capabilities)
        @bridge = bridge
        @capabilities = capabilities
        @mutex = Mutex.new
        @initialized = false
        @config = {
          CHECK_ON_OPEN => null_coalesce(@capabilities.initialization_option(CHECK_ON_OPEN), true),
          CHECK_ON_SAVE => null_coalesce(@capabilities.initialization_option(CHECK_ON_SAVE), true),
          CHECK_ON_CHANGE => null_coalesce(@capabilities.initialization_option(CHECK_ON_CHANGE), true),
          ONLY_SINGLE_FILE => null_coalesce(@capabilities.initialization_option(ONLY_SINGLE_FILE), false),
        }
      end

      def fetch(force: nil)
        @mutex.synchronize do
          return unless @capabilities.supports_workspace_configuration?
          return if initialized? && !force

          keys = [
            CHECK_ON_OPEN,
            CHECK_ON_SAVE,
            CHECK_ON_CHANGE,
            ONLY_SINGLE_FILE,
          ]

          configs = @bridge.send_request(
            "workspace/configuration",
            items: keys.map do |key|
              { section: key }
            end
          )

          keys.each.with_index do |key, i|
            @config[key] = configs[i] unless configs[i].nil?
          end

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

      def only_single_file?
        fetch # making sure we have for an initialized value
        @config[ONLY_SINGLE_FILE]
      end

      def null_coalesce(value, default)
        value.nil? ? default : value
      end
    end
  end
end
