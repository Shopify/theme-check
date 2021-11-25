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

      def execute(arguments)
        raise NotImplementedError
      end

      def command
        self.class.command
      end
    end
  end
end
