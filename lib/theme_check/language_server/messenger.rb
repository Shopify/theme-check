# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Messenger
      def initialize
        @responses = {}
        @mutex = Mutex.new
        @id = 0
      end

      # Here's how you'd use this:
      #
      # def some_method_that_communicates_both_ways
      #
      #   # this will block until the JSON rpc loop has an answer
      #   token = @server.request do |id|
      #     send_create_work_done_progress_request(id, ...)
      #   end
      #
      #   send_create_work_done_begin_notification(token, "...")
      #
      #   do_stuff do |file, i, total|
      #     send_create_work_done_progress_notification(token, "...")
      #   end
      #
      #   send_create_work_done_end_notification(token, "...")
      #
      # end
      def request(&block)
        id = @mutex.synchronize { @id += 1 }
        @responses[id] = SizedQueue.new(1)

        # Execute the block in the parent thread with an ID
        # So that we're able to relinquish control in the right
        # place when we have a response.
        block.call(id)

        # this call is blocking until we get a response from somewhere
        result = @responses[id].pop

        # cleanup when done
        @responses.delete(id)

        # return the response
        result
      end

      # In the JSONRPC loop, when we find the response to the
      # request, we unblock the thread that made the request with the
      # response.
      def respond(id, value)
        @responses[id] << value
      end
    end
  end
end
