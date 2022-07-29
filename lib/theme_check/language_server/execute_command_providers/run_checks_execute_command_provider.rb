# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class RunChecksExecuteCommandProvider < ExecuteCommandProvider
      include URIHelper

      command "runChecks"

      def initialize(diagnostics_engine, storage, linter_config, language_server_config)
        @diagnostics_engine = diagnostics_engine
        @storage = storage
        @linter_config = linter_config
        @language_server_config = language_server_config
      end

      def execute(_args)
        @diagnostics_engine.analyze_and_send_offenses(
          @storage.opened_files.map { |relative_path| @storage.path(relative_path) },
          @linter_config,
          only_single_file: @language_server_config.only_single_file?,
          force: true
        )
        nil
      end
    end
  end
end
