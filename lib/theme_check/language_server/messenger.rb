# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Messenger
      def send_message
        raise NotImplementedError
      end

      def read_message
        raise NotImplementedError
      end

      def log
        raise NotImplementedError
      end

      def close_input
        raise NotImplementedError
      end

      def close_output
        raise NotImplementedError
      end
    end
  end
end
