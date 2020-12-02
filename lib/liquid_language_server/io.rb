# frozen_string_literal: true

require 'json'

module LiquidLanguageServer
  class IO
    def initialize(server)
      @server = server
      @log = File.open("/tmp/lsp.log", "a")
      @err = File.open("/tmp/lsp.err", "a")

      loop do
        response = process_request
        type = response[:type]
        case type
        when "notification"
          ## type NotificationMessage
          respond_with(prepare_notification(
            response[:message],
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
          exit(true)
        end

      # support ctrl+c and stuff
      rescue SignalException
        exit(true)

      rescue Exception => e
        error(e, e.backtrace)
        exit(false)
      end
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
    def prepare_notification(message, params)
      {
        jsonrpc: '2.0',
        method: message,
        params: params,
      }
    end

    def respond_with(response, io = STDOUT)
      response_body = JSON.unparse(response)
      log_json(response_body)

      io.write("Content-Length: #{response_body.length + 0}\r\n")
      io.write("\r\n")
      io.write(response_body)
      io.flush
    end

    def process_request
      request_body = get_request
      request_json = JSON.parse(request_body)
      log_json(request_body)

      id = request_json['id']
      method_name = request_json['method']
      params = request_json['params']

      method_name = "on_#{method_name.gsub(/[^\w]/, '_')}"

      if @server.respond_to?(method_name)
        @server.send(method_name, id, params)
      else
        @err.puts("SERVER DOES NOT RESPOND TO #{method_name}")
        nil
      end
    end

    def get_request
      initial_line = STDIN.gets

      # STDIN.gets returning nil means the stream was closed.
      # It means we're done.
      return '{ "method": "exit" }' if initial_line.nil?

      length = initial_line.match(/Content-Length: (\d+)/)[1].to_i
      content = ''
      while content.length < length + 2
        begin
          # Why + 2? Because \r\n
          content += STDIN.read(length + 2)
        rescue Exception => e
          error(e, e.backtrace)
          # We have almost certainly been disconnected from the server
          cleanup
          exit!(1)
        end
      end

      content
    end

    def cleanup
      @err.close
      @log.close
    end

    def log_json(json)
      @log.puts(json)
    end

    def log(message)
      @log.puts(JSON.unparse({
        message: message,
      }))
    end

    def error(message, backtrace = nil)
      @log.puts(JSON.unparse({
        error: message,
        backtrace: backtrace,
      }))
    end
  end
end
