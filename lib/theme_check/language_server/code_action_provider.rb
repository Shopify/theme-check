# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CodeActionProvider
      class << self
        def all
          @all ||= []
        end

        def inherited(subclass)
          all << subclass
        end

        def kind(k = nil)
          @kind = k unless k.nil?
          @kind
        end
      end

      attr_reader :diagnostics_tracker

      def initialize(diagnostics_tracker)
        @diagnostics_tracker = diagnostics_tracker
      end

      def kind
        self.class.kind
      end

      def code_actions(relative_path, range)
        raise NotImplementedError
      end
    end
  end
end
