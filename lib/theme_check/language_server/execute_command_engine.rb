# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ExecuteCommandEngine
      def initialize
        @providers = {}
      end

      def <<(provider)
        @providers[provider.command] = provider
      end

      def execute(command, arguments)
        @providers[command].execute(arguments)
      end
    end
  end
end
