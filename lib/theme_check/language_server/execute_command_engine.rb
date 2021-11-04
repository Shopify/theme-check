# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ExecuteCommandEngine
      def initialize(storage, bridge, diagnostics_manager)
        @providers = {}
        ExecuteCommandProvider.all
          .map { |c| c.new(storage, bridge, diagnostics_manager) }
          .each { |p| @providers[p.command] = p }
      end

      def execute(command, arguments)
        @providers[command].execute(arguments)
      end
    end
  end
end
