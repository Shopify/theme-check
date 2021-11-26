# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class IOMessenger < Messenger
      def self.err_stream
        if ThemeCheck.debug_log_file
          File.open(ThemeCheck.debug_log_file, "w")
        else
          STDERR
        end
      end

      def initialize(
        in_stream: STDIN,
        out_stream: STDOUT,
        err_stream: IOMessenger.err_stream
      )
        validate!([in_stream, out_stream, err_stream])

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

        # Lock for writing, otherwise messages might be interspersed.
        @writer = Mutex.new
      end

      def read_message
        length = initial_line.match(/Content-Length: (\d+)/)[1].to_i
        content = ''
        length_to_read = 2 + length # 2 is the empty line length (\r\n)
        while content.length < length_to_read
          chunk = @in.read(length_to_read - content.length)
          raise DoneStreaming if chunk.nil?
          content += chunk
        end
        content.lstrip!
      rescue IOError
        raise DoneStreaming
      end

      def send_message(message_body)
        @writer.synchronize do
          @out.write("Content-Length: #{message_body.bytesize}\r\n")
          @out.write("\r\n")
          @out.write(message_body)
          @out.flush
        end
      end

      def log(message)
        @err.puts(message)
        @err.flush
      end

      def close_input
        @in.close unless @in.closed?
      end

      def close_output
        @err.close
        @out.close
      end

      private

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
    end
  end
end
