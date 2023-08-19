# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class BridgeTest < Minitest::Test
      def setup
        @messenger = MockMessenger.new
        @bridge = Bridge.new(@messenger)
      end

      def test_send_message_adds_jsonrpc_2
        @bridge.send_message({
          id: 1,
          result: {},
        })
        assert_includes(@messenger.sent_messages, {
          jsonrpc: "2.0",
          id: 1,
          result: {},
        })
      end

      def test_send_notification
        @bridge.send_notification("text/foo", { x: 1 })
        assert_includes(@messenger.sent_messages, {
          jsonrpc: "2.0",
          method: "text/foo",
          params: {
            x: 1,
          },
        })
      end

      def test_send_response
        @bridge.send_response(1, { x: 1 })
        assert_includes(@messenger.sent_messages, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            x: 1,
          },
        })
      end

      def test_send_progress
        @bridge.send_progress("token", { x: 1 })
        assert_includes(@messenger.sent_messages, {
          jsonrpc: "2.0",
          method: "$/progress",
          params: {
            token: "token",
            value: {
              x: 1,
            },
          },
        })
      end

      def test_read_message_as_json_with_symbols_for_keys
        expected = {
          jsonrpc: "2.0",
          method: "textDocument/didOpen",
          params: {
            x: 1,
          },
        }

        # In a thread, we wait for messages
        t = Thread.new do
          @bridge.read_message
        end

        # In another, we send a JSON dump of the expected message
        @messenger.send_mock_message(JSON.dump(expected))

        # We expect the message to be received as a hash
        assert_equal(expected, t.join(0.5).value)
      end

      def test_send_and_receive_requests
        expected_result = { x: 1 }

        # Send a request from a thread, return the result resolved from another
        t = Thread.new do
          @bridge.send_request("window/workDoneProgress/create", { token: "token" })
        end

        # Client receives the request
        mock_client = Thread.new do
          loop while @messenger.sent_messages.empty?
          @messenger.sent_messages.pop
        end

        # Will reuse ID from the request
        request = mock_client.join(1).value
        request_id = request[:id]

        # From a different thread, we resolve the promise
        @bridge.receive_response(request_id, expected_result)

        assert_equal(expected_result, t.join(0.5).value)
      end
    end
  end
end
