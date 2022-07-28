# frozen_string_literal: true

require 'json'
require 'stringio'
require 'timeout'

module ThemeCheck
  module LanguageServer
    class DoneStreaming < StandardError; end

    class IncompatibleStream < StandardError; end

    class Server
      attr_reader :handler
      attr_reader :should_raise_errors

      def initialize(
        messenger:,
        should_raise_errors: false,
        number_of_threads: 2
      )
        # This is what does the IO
        @messenger = messenger

        # This is what you use to communicate with the language client
        @bridge = Bridge.new(@messenger)

        # The handler handles messages from the language client
        @handler = Handler.new(@bridge)

        # The queue holds the JSON RPC messages
        @queue = Queue.new

        # The JSON RPC thread pushes messages onto the queue
        @json_rpc_thread = nil

        # The handler threads read messages from the queue
        @number_of_threads = number_of_threads
        @handlers = []

        # The error queue holds blocks the main thread. When filled, we exit the program.
        @error = SizedQueue.new(number_of_threads)

        @should_raise_errors = should_raise_errors
      end

      def listen
        start_handler_threads
        start_json_rpc_thread
        err = @error.pop
        status_code = status_code_from_error(err)

        if status_code > 0
          # For a reason I can't comprehend, this hangs but prints
          # anyway. So it's wrapped in this ugly timeout...
          Timeout.timeout(1) do
            $stderr.puts err.full_message
          end

          # Warn user of error, otherwise server might restart
          # without telling you.
          @bridge.send_notification("window/showMessage", {
            type: 1,
            message: "A theme-check-language-server error has occurred, search OUTPUT logs for details.",
          })
        end

        cleanup(status_code)
      rescue SignalException
        0
      rescue StandardError
        2
      end

      def start_json_rpc_thread
        @json_rpc_thread = Thread.new do
          loop do
            message = @bridge.read_message
            if message[:method] == 'initialize'
              handle_message(message)
            elsif message.key?(:result)
              # Responses are handled on the main thread to prevent
              # a potential deadlock caused by all handlers waiting
              # for a responses.
              handle_response(message)
            else
              @queue << message
            end
          end
        rescue Exception => e # rubocop:disable Lint/RescueException
          @bridge.log("rescuing #{e.class} in jsonrpc thread")
          @error << e
        end
      end

      def start_handler_threads
        @number_of_threads.times do
          @handlers << Thread.new do
            handle_messages
          end
        end
      end

      def handle_messages
        loop do
          message = @queue.pop
          return if @queue.closed? && @queue.empty?

          handle_message(message)
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        @bridge.log("rescuing #{e.class} in handler thread")
        @error << e
      end

      def status_code_from_error(e)
        raise e

      # support ctrl+c and stuff
      rescue SignalException, DoneStreaming
        0
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise e if should_raise_errors

        @bridge.log("Fatal #{e.class}")
        2
      end

      private

      def handle_message(message)
        id = message[:id]
        method_name = message[:method]
        method_name &&= "on_#{to_snake_case(method_name)}"
        params = message[:params]

        if @handler.respond_to?(method_name)
          @handler.send(method_name, id, params)
        end
      rescue DoneStreaming => e
        raise e
      rescue StandardError => e
        is_request = id
        raise e unless is_request

        # Errors obtained in request handlers should be sent
        # back as internal errors instead of closing the program.
        @bridge.send_internal_error(id, e)
      end

      def handle_response(message)
        id = message[:id]
        result = message[:result]
        @bridge.receive_response(id, result)
      end

      def to_snake_case(method_name)
        StringHelpers.underscore(method_name.gsub(/[^\w]/, '_'))
      end

      def cleanup(status_code)
        @bridge.log("Closing server... status code = #{status_code}")
        # Stop listenting to RPC calls
        @messenger.close_input
        # Wait for rpc loop to close
        @json_rpc_thread&.join if @json_rpc_thread&.alive?
        # Close the queue
        @queue.close unless @queue.closed?
        # Give 10 seconds for the handlers to wrap up what they were
        # doing/emptying the queue. 👀 unit tests.
        @handlers.each { |thread| thread.join(10) if thread.alive? }

        # Hijack the status_code if an error occurred while cleaning up.
        # 👀 unit tests.
        until @error.empty?
          code = status_code_from_error(@error.pop)
          # Promote the status_code to ERROR if one of the threads
          # resulted in an error, otherwise leave the status_code as
          # is. That's because one thread could end successfully in a
          # DoneStreaming error while the other failed with an
          # internal error. If we had an internal error, we should
          # return with a status_code that fits.
          status_code = code if code > status_code
        end
        status_code
      ensure
        @messenger.close_output
      end
    end
  end
end
