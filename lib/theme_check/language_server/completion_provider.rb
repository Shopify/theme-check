# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionProvider
      include CompletionHelper
      include RegexHelpers

      class << self
        def all
          @all ||= []
        end

        def inherited(subclass)
          all << subclass
        end
      end

      def initialize(storage = InMemoryStorage.new)
        @storage = storage
      end

      def completions(content, cursor)
        raise NotImplementedError
      end
    end
  end
end
