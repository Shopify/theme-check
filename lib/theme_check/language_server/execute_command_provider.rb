# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ExecuteCommandProvider
      class << self
        def all
          @all ||= []
        end

        def inherited(subclass)
          all << subclass
        end

        def command(cmd = nil)
          @command = cmd unless cmd.nil?
          @command
        end
      end

      attr_reader :storage, :bridge, :diagnostics_manager

      def initialize(storage, bridge, diagnostics_manager)
        @storage = storage
        @bridge = bridge
        @diagnostics_manager = diagnostics_manager
      end

      def execute(arguments)
        raise NotImplementedError
      end

      def command
        self.class.command
      end
    end
  end
end
