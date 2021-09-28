# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ExecuteCommandEngine
      def initialize(bridge, diagnostics_tracker)
        @providers = {}
        ExecuteCommandProvider.all
          .map { |c| c.new(bridge, diagnostics_tracker) }
          .each { |p| @providers[p.command] = p }
      end

      def execute(command, arguments)
        @providers[command].execute(arguments)
      end
    end
  end
end
