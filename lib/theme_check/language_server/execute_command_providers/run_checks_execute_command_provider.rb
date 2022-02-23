# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class RunChecksExecuteCommandProvider < ExecuteCommandProvider
      include URIHelper

      command "runChecks"

      def initialize(diagnostics_engine, root_path, root_config)
        @diagnostics_engine = diagnostics_engine
        @root_path = root_path
        @root_config = root_config
      end

      def execute(_args)
        @diagnostics_engine.analyze_and_send_offenses(
          @root_path,
          @root_config,
          only_single_file: false,
          force: true
        )
        nil
      end
    end
  end
end
