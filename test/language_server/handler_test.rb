# frozen_string_literal: true

require "test_helper"

module ThemeCheck
  module LanguageServer
    class HandlerTest < Minitest::Test
      include URIHelper

      def setup
        @server = MockServer.new
        @handler = Handler.new(@server)
        @path = "layout/theme.liquid"
        @storage = make_file_system_storage(@path => "<html>hello world</html>\n")
      end

      def test_handle_initialize_no_path
        initialize!(1, nil, nil)
        assert_includes(@server.responses, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: {},
          },
        })
      end

      def test_handle_initialize_with_root_uri
        initialize!(1, @storage.root)
        assert_includes(@server.responses, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: Handler::CAPABILITIES,
          },
        })
      end

      def test_handle_initialize_with_root_path
        initialize!(1, nil, @storage.root)
        assert_includes(@server.responses, {
          jsonrpc: "2.0",
          id: 1,
          result: {
            capabilities: Handler::CAPABILITIES,
          },
        })
      end

      def test_handle_document_did_open
        initialize!(1, nil, @storage.root)
        text_document_did_open!(@path)
        assert_equal(@handler.storage.read(@path), @storage.read(@path))
      end

      def test_handle_document_did_change_full
        initialize!(1, @storage.root)
        text_document_did_open!(@path)
        text_document_did_change!(@path, [{ "text" => "hi there" }])
        assert_equal("hi there", @handler.storage.read(@path))
      end

      def test_handle_document_did_change_incremental
        initialize!(1, @storage.root)
        text_document_did_open!(@path)
        text_document_did_change!(@path, [
          {
            "text" => "hi there",
            "range" => {
              "start" => {
                "line" => 0,
                "character" => 0,
              },
              "end" => {
                "line" => 1,
                "character" => 0,
              },
            },
          },
          {
            "text" => "friend",
            "range" => {
              "start" => {
                "line" => 0,
                "character" => 3,
              },
              "end" => {
                "line" => 0,
                "character" => 7,
              },
            },
          },
        ])
        assert_equal("hi friend", @handler.storage.read(@path))
      end

      focus
      def test_benchmark_incremental_vs_full_buffer
        require 'benchmark'
        initialize!(1, @storage.root)
        text_document_did_open!(@path)

        Benchmark.bm do |benchmark|
          benchmark.report('FULL') do
            5000.times do
              text_document_did_change!(@path, [{
                "text" => ("hi world\n" * 14999 + "hi bobby\n").dup,
              }])
            end
          end

          benchmark.report('INCREMENTAL') do
            5000.times do
              text_document_did_change!(@path, [{
                "text" => "hi bobby",
                "range" => {
                  "start" => {
                    "line" => 14999,
                    "character" => 0,
                  },
                  "end" => {
                    "line" => 14999,
                    "character" => 8,
                  },
                },
              }])
            end
          end
        end
      end

      private

      def initialize!(id, root_uri_path, root_path = nil)
        @handler.on_initialize(id, {
          "rootUri" => root_uri_path.nil? ? nil : file_uri(root_uri_path),
          "rootPath" => root_path,
        })
      end

      def text_document_did_open!(path)
        @handler.on_text_document_did_open(nil, {
          "textDocument" => {
            "uri" => file_uri(@storage.path(path)),
            "version" => 1,
            "text" => @storage.read(path),
          },
        })
      end

      def text_document_did_change!(path, content_changes)
        @handler.on_text_document_did_change(nil, {
          "textDocument" => {
            "uri" => file_uri(@storage.path(path)),
            "version" => 2,
          },
          "contentChanges" => content_changes,
        })
      end
    end

    class MockServer
      attr_accessor :strings, :responses

      def initialize
        @strings = []
        @responses = []
      end

      def send_response(hash)
        @responses << hash
      end

      def log(s)
        strings << s
      end
    end
  end
end
