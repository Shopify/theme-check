# frozen_string_literal: true

require 'json'

module LiquidLanguageServer
  class DoneStreaming < StandardError; end
  class LSPProtocolError < StandardError; end

  class Server
    def initialize(
      router:,
      in_stream: STDIN,
      out_stream: STDOUT,
      err_stream: STDERR
    )
      @router = router
      @in = in_stream
      @out = out_stream
      @err = err_stream
    end

    def listen
      loop do
        response = process_request
        type = response[:type]
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
        error("Done streamin'!")
        return 0

      rescue Exception => e
        error(e, e.backtrace)
        return 1
      end
    end

    private

    def process_request
      request_body = get_request
      request_json = JSON.parse(request_body)
      log_json(request_body)

      id = request_json['id']
      method_name = request_json['method']
      params = request_json['params']

      method_name = "on_#{method_name.gsub(/[^\w]/, '_')}"

      if @router.respond_to?(method_name)
        @router.send(method_name, id, params)
      else
        @err.puts("ROUTER DOES NOT RESPOND TO #{method_name}")
        nil
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

    def get_request
      length = initial_line.match(/Content-Length: (\d+)/)[1].to_i
      content = ''
      while content.length < length + 2
        begin
          # Why + 2? Because \r\n
          content += @in.read(length + 2)
        rescue Exception => e
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
      begin
        @err.close
        @out.close
      rescue
        # I did my best
      end
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
  end
end
