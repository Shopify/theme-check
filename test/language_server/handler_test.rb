# frozen_string_literal: true

require "test_helper"

module ThemeCheck
  module LanguageServer
    class HandlerTest < Minitest::Test
      include URIHelper

      def setup
        @mock_messenger = MockMessenger.new
        @bridge = Bridge.new(@mock_messenger)
        @handler = Handler.new(@bridge)
        @storage = make_file_system_storage("layout/theme.liquid" => "<html>hello world</html>")
      end

      def test_handle_initialize_no_path
        initialize!(1, nil, nil)
        assert_includes(@mock_messenger.sent_messages, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: {},
          },
        })
      end

      def test_handle_initialize_with_root_uri
        initialize!(1, @storage.root)
        assert_includes(@mock_messenger.sent_messages, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: Handler::CAPABILITIES,
            serverInfo: Handler::SERVER_INFO,
          },
        })
      end

      def test_handle_initialize_with_root_path
        initialize!(1, nil, @storage.root)
        assert_includes(@mock_messenger.sent_messages, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: Handler::CAPABILITIES,
            serverInfo: Handler::SERVER_INFO,
          },
        })
      end

      def test_handle_document_did_open
        initialize!(1, nil, @storage.root)
        @handler.on_text_document_did_open(nil, {
          "textDocument" => {
            "uri" => file_uri(@storage.path('layout/theme.liquid')),
            "version" => 1,
          },
        })
      end

      private

      def initialize!(id, root_uri_path, root_path = nil)
        @handler.on_initialize(id, {
          "rootUri" => root_uri_path.nil? ? nil : file_uri(root_uri_path),
          "rootPath" => root_path,
        })
      end
    end
  end
end
