# frozen_string_literal: true
require 'json'
require 'stringio'

module ThemeCheck
  module LanguageServer
    class DoneStreaming < StandardError; end

    class IncompatibleStream < StandardError; end

    class Server
      attr_reader :handler
      attr_reader :should_raise_errors

      def initialize(
        in_stream: STDIN,
        out_stream: STDOUT,
        err_stream: STDERR,
        should_raise_errors: false,
        number_of_threads: 2
      )
        validate!([in_stream, out_stream, err_stream])

        @handler = Handler.new(self)
        @in = in_stream
        @out = out_stream
        @err = err_stream

        # Because programming is fun,
        #
        # Ruby on Windows turns \n into \r\n. Which means that \r\n
        # gets turned into \r\r\n. Which means that the protocol
        # breaks on windows unless we turn STDOUT into binary mode.
        #
        # Hours wasted: 9.
        @out.binmode

        @out.sync = true # do not buffer
        @err.sync = true # do not buffer

        # The queue holds the JSON RPC messages
        @queue = Queue.new

        # The JSON RPC thread pushes messages onto the queue
        @json_rpc_thread = nil

        # The handler threads read messages from the queue
        @number_of_threads = number_of_threads
        @handlers = []

        # The messenger permits requests to be made from the handler
        # to the language client and for those messages to be resolved in place.
        @messenger = Messenger.new

        # The error queue holds blocks the main thread. When filled, we exit the program.
        @error = SizedQueue.new(1)

        @should_raise_errors = should_raise_errors
      end

      def listen
        start_handler_threads
        start_json_rpc_thread
        status_code_from_error(@error.pop)
      rescue SignalException
        0
      ensure
        cleanup
      end

      def start_json_rpc_thread
        @json_rpc_thread = Thread.new do
          loop do
            message = read_json_rpc_message
            if message['method'] == 'initialize'
              handle_message(message)
            else
              @queue << message
            end
          rescue Exception => e # rubocop:disable Lint/RescueException
            break @error << e
          end
        end
      end

      def start_handler_threads
        @number_of_threads.times do
          @handlers << Thread.new do
            loop do
              message = @queue.pop
              break if @queue.closed? && @queue.empty?
              handle_message(message)
            rescue Exception => e # rubocop:disable Lint/RescueException
              break @error << e
            end
          end
        end
      end

      def status_code_from_error(e)
        raise e

      # support ctrl+c and stuff
      rescue SignalException, DoneStreaming
        0

      rescue Exception => e # rubocop:disable Lint/RescueException
        raise e if should_raise_errors
        log(e)
        log(e.backtrace)
        2
      end

      def request(&block)
        @messenger.request(&block)
      end

      def send_message(message)
        message_body = JSON.dump(message)
        log(JSON.pretty_generate(message)) if $DEBUG

        @out.write("Content-Length: #{message_body.bytesize}\r\n")
        @out.write("\r\n")
        @out.write(message_body)
        @out.flush
      end

      def log(message)
        @err.puts(message)
        @err.flush
      end

      private

      def supported_io_classes
        [IO, StringIO]
      end

      def validate!(streams = [])
        streams.each do |stream|
          unless supported_io_classes.find { |klass| stream.is_a?(klass) }
            raise IncompatibleStream, incompatible_stream_message
          end
        end
      end

      def incompatible_stream_message
        'if provided, in_stream, out_stream, and err_stream must be a kind of '\
        "one of the following: #{supported_io_classes.join(', ')}"
      end

      def read_json_rpc_message
        message_body = read_new_content
        message_json = JSON.parse(message_body)
        log(JSON.pretty_generate(message_json)) if $DEBUG
        message_json
      end

      def handle_message(message)
        id = message['id']
        method_name = message['method']
        method_name &&= "on_#{to_snake_case(method_name)}"
        params = message['params']
        result = message['result']

        if message.key?('result')
          @messenger.respond(id, result)
        elsif @handler.respond_to?(method_name)
          @handler.send(method_name, id, params)
        end
      end

      def to_snake_case(method_name)
        StringHelpers.underscore(method_name.gsub(/[^\w]/, '_'))
      end

      def initial_line
        # Scanning for lines that fit the protocol.
        while true
          initial_line = @in.gets
          # gets returning nil means the stream was closed.
          raise DoneStreaming if initial_line.nil?

          if initial_line.match(/Content-Length: (\d+)/)
            break
          end
        end
        initial_line
      end

      def read_new_content
        length = initial_line.match(/Content-Length: (\d+)/)[1].to_i
        content = ''
        while content.length < length + 2
          # Why + 2? Because \r\n
          content += @in.read(length + 2)
          raise DoneStreaming if @in.closed?
        end

        content
      end

      def cleanup
        # Stop listenting to RPC calls
        @in.close unless @in.closed?
        # Wait for rpc loop to close
        @json_rpc_thread&.join if @json_rpc_thread&.alive?
        # Close the queue
        @queue.close unless @queue.closed?
        # Give 10 seconds for the handlers to wrap up what they were
        # doing/emptying the queue. 👀 unit tests.
        @handlers.each { |thread| thread.join(10) if thread.alive? }
      ensure
        @err.close
        @out.close
      end
    end
  end
end
