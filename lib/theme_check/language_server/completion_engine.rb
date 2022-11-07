# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CompletionEngine
      def initialize(storage, bridge = nil)
        @storage = storage
        @bridge = bridge
        @providers = CompletionProvider.all.map { |x| x.new(storage) }
      end

      def completions(relative_path, line, col)
        @providers.flat_map do |provider|
          provider.completions(relative_path, line, col)
        end
      rescue StandardError => error
        @bridge || raise(error)

        message = error.message
        backtrace = error.backtrace.join("\n")

        @bridge.log("[completion error] error: #{message}\n#{backtrace}")
      end
    end
  end
end
