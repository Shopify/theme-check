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
        should_raise_errors: false
      )
        validate!([in_stream, out_stream, err_stream])

        @handler = Handler.new(self)
        @in = in_stream
        @out = out_stream
        @err = err_stream

        @out.sync = true # do not buffer
        @err.sync = true # do not buffer

        @should_raise_errors = should_raise_errors
      end

      def listen
        loop do
          process_request

        # support ctrl+c and stuff
        rescue SignalException, DoneStreaming
          cleanup
          return 0

        rescue Exception => e # rubocop:disable Lint/RescueException
          raise e if should_raise_errors
          log(e)
          log(e.backtrace)
          return 1
        end
      end

      def send_response(response)
        response_body = JSON.dump(response)
        log(JSON.pretty_generate(response)) if $DEBUG

        # Because programming is fun,
        #
        # Ruby on Windows turns \n into \r\n. Which means that \r\n
        # gets turned into \r\r\n. Which means that the protocol
        # breaks on windows unless we turn STDOUT into binary mode and
        # set the encoding manually (yuk!) or we do this little hack
        # here and put \n which gets transformed into \r\n on windows
        # only...
        #
        # Hours wasted: 8.
        eol = Gem.win_platform? ? "\n" : "\r\n"
        @out.write("Content-Length: #{response_body.bytesize}#{eol}")
        @out.write(eol)
        @out.write(response_body)
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

      def process_request
        request_body = read_new_content
        request_json = JSON.parse(request_body)
        log(JSON.pretty_generate(request_json)) if $DEBUG

        id = request_json['id']
        method_name = request_json['method']
        params = request_json['params']
        method_name = "on_#{to_snake_case(method_name)}"

        if @handler.respond_to?(method_name)
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
          begin
            # Why + 2? Because \r\n
            content += @in.read(length + 2)
          rescue => e
            log(e)
            log(e.backtrace)
            # We have almost certainly been disconnected from the server
            cleanup
            raise DoneStreaming
          end
        end

        content
      end

      def cleanup
        @err.close
        @out.close
      rescue
        # I did my best
      end
    end
  end
end
