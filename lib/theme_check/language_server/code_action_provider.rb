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

      attr_reader :storage
      attr_reader :diagnostics_manager

      def initialize(storage, diagnostics_manager)
        @storage = storage
        @diagnostics_manager = diagnostics_manager
      end

      def kind
        self.class.kind
      end

      def base_kind
        kind.split('.')[0]
      end

      def code_actions(relative_path, range)
        raise NotImplementedError
      end
    end
  end
end
