# frozen_string_literal: true

require "timeout"

# This class exists as a bridge (or boundary) between our handlers and the outside world.
#
# It is concerned with all the Language Server Protocol constructs. i.e.
#
#   - sending Hash messages as JSON
#   - reading JSON messages as Hashes
#   - preparing, sending and resolving requests
#   - preparing and sending responses
#   - preparing and sending notifications
#   - preparing and sending progress notifications
#
# But it _not_ concerned by _how_ those messages are sent to the
# outside world. That's the job of the messenger.
#
# This enables us to have all the language server protocol logic
# in here living independently of how we communicate with the
# client (STDIO or websocket)
module ThemeCheck
  module LanguageServer
    class Bridge
      attr_writer :supports_work_done_progress

      def initialize(messenger)
        # The messenger is responsible for IO.
        # Could be STDIO or WebSockets or Mock.
        @messenger = messenger

        # Whether the client supports work done progress notifications
        @supports_work_done_progress = false

        @work_done_progress_mutex = Mutex.new
        @work_done_progress_token = 1
      end

      def log(message)
        @messenger.log(message)
      end

      def read_message
        message_body = @messenger.read_message
        message_json = JSON.parse(message_body, symbolize_names: true)
        @messenger.log(JSON.pretty_generate(message_json)) if ThemeCheck.debug?
        message_json
      end

      def send_message(message_hash)
        message_hash[:jsonrpc] = '2.0'
        message_body = JSON.dump(message_hash)
        @messenger.log(JSON.pretty_generate(message_hash)) if ThemeCheck.debug?
        @messenger.send_message(message_body)
      end

      # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#requestMessage
      def send_request(method, params = nil)
        channel = Channel.create
        message = { id: channel.id }
        message[:method] = method
        message[:params] = params if params
        send_message(message)
        channel.pop
      ensure
        channel.close
      end

      def receive_response(id, result)
        Channel.by_id(id) << result
      end

      # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#responseMessage
      def send_response(id, result = nil, error = nil)
        message = { id: id }
        if error
          message[:error] = error
        else
          message[:result] = result
        end
        send_message(message)
      end

      # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#responseError
      def send_internal_error(id, e)
        # For a reason I can't comprehend, sometimes
        # e.full_message _hangs_ and brings your CPU to 100%.
        # It's wrapped in here because it prints anyway...
        # This shit is weird, yo.
        Timeout.timeout(1) do
          $stderr.puts e.full_message
        end
      ensure
        send_response(id, nil, {
          code: ErrorCodes::INTERNAL_ERROR,
          message: "A theme-check-language-server has occured, inspect OUTPUT logs for details.",
        })
      end

      # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
      def send_notification(method, params)
        message = { method: method }
        message[:params] = params
        send_message(message)
      end

      # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#progress
      def send_progress(token, value)
        send_notification("$/progress", token: token, value: value)
      end

      def supports_work_done_progress?
        @supports_work_done_progress
      end

      def send_create_work_done_progress_request
        # This isn't necessary, but it kind of is to make it obvious
        # that this variable is not thread safe. Don't try to refactor
        # this with @work_done_progress_token because you're going to
        # have a hard time.
        token = @work_done_progress_mutex.synchronize do
          @work_done_progress_token += 1
        end

        return token unless supports_work_done_progress?

        # We're going to wait for a response here...
        send_request("window/workDoneProgress/create", {
          token: token,
        })

        token
      end

      def send_work_done_progress_begin(token, title)
        return unless supports_work_done_progress?

        send_progress(token, {
          kind: 'begin',
          title: title,
          cancellable: false,
          percentage: 0,
        })
      end

      def send_work_done_progress_report(token, message, percentage)
        return unless supports_work_done_progress?

        send_progress(token, {
          kind: 'report',
          message: message,
          cancellable: false,
          percentage: percentage,
        })
      end

      def send_work_done_progress_end(token, message)
        return unless supports_work_done_progress?

        send_progress(token, {
          kind: 'end',
          message: message,
        })
      end
    end
  end
end
