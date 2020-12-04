# frozen_string_literal: true
require 'json'
require 'stringio'

module LiquidLanguageServer
  class DoneStreaming < StandardError; end
  class IncompatibleStream < StandardError; end

  class Server
    def initialize(
      router:,
      in_stream: STDIN,
      out_stream: STDOUT,
      err_stream: STDERR
    )
      validate!([in_stream, out_stream, err_stream])

      @router = router
      @in = in_stream
      @out = out_stream
      @err = err_stream

      @out.sync = true # do not buffer
      @err.sync = true # do not buffer
    end

    def listen
      loop do
        response = process_request
        type = response.fetch(:type, "")
        case type
        when "notification"
          ## type NotificationMessage
          respond_with(prepare_notification(
            response[:method],
            response[:params]
          ))
        when "response"
          respond_with(prepare_response(
            response[:id],
            response[:result]
          ))
        when "log"
          log(response[:message])
        when "exit"
          cleanup
          return 0
        end

      # support ctrl+c and stuff
      rescue SignalException, DoneStreaming
        log("Done streamin'!")
        return 0

      rescue => e
        error(e, e.backtrace)
        return 1
      end
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
      # DEBUG
      # log_json(request_body)

      id = request_json['id']
      method_name = request_json['method']
      params = request_json['params']

      method_name = "on_#{snake_case(method_name)}"

      if @router.respond_to?(method_name)
        @router.send(method_name, id, params)
      else
        log("ROUTER DOES NOT RESPOND TO #{method_name}")
        {}
      end
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
          error(e, e.backtrace)
          # We have almost certainly been disconnected from the server
          cleanup
          raise DoneStreaming
        end
      end

      content
    end

    def respond_with(response)
      response_body = JSON.dump(response)
      log_json(response_body)

      @out.write("Content-Length: #{response_body.length + 0}\r\n")
      @out.write("\r\n")
      @out.write(response_body)
      @out.flush
    end

    # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#responseMessage
    def prepare_response(id, result)
      {
        jsonrpc: '2.0',
        id: id,
        result: result,
      }
    end

    # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
    def prepare_notification(method, params)
      {
        jsonrpc: '2.0',
        method: method,
        params: params,
      }
    end

    def cleanup
      @err.close
      @out.close
    rescue
      # I did my best
    end

    def log_json(json)
      @err.puts(json)
    end

    def log(message)
      @err.puts(JSON.unparse({
        message: message,
      }))
    end

    def error(message, backtrace = nil)
      @err.puts(JSON.unparse({
        error: message,
        backtrace: backtrace,
      }))
    end

    def snake_case(method_name)
      method_name
        .gsub(/[^\w]/, '_')
        .gsub(/(\w)([A-Z])/) { "#{Regexp.last_match(1)}_#{Regexp.last_match(2).downcase}" }
    end
  end
end
