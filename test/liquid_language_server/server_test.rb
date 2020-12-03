# frozen_string_literal: true
require "test_helper"
require 'stringio'

class ServerTest < Minitest::Test
  def setup
    @router = Minitest::Mock.new
    @in = StringIO.new
    @out = StringIO.new
    @err = StringIO.new

    @server = LiquidLanguageServer::Server.new(
      router: @router,
      in_stream: @in,
      out_stream: @out,
      err_stream: @err
    )
  end

  def test_server_turns_notification_responses_into_valid_notifications
    @router.expect(
      :on_textDocument_didOpen,
      {
        type: 'notification',
        method: 'hello_world',
        params: [],
      },
      [nil, Hash],
    )

    send_message(text_document_did_open_message)

    assert_equal(
      "Content-Length: 52\r\n\r\n{\"jsonrpc\":\"2.0\",\"method\":\"hello_world\",\"params\":[]}",
      @out.string,
    )
  end

  def test_server_turns_notification_responses_into_valid_responses
    @router.expect(
      :on_textDocument_didOpen,
      {
        type: 'response',
        id: 1,
        result: {},
      },
      [nil, Hash],
    )

    send_message(text_document_did_open_message)

    puts(@out.string)
    assert_equal(
      "Content-Length: 36\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{}}",
      @out.string,
    )
  end

  private

  def send_message(str)
    @in.puts(str)
    @in.rewind
    @server.listen
    @out.rewind
    @err.rewind
  end

  def text_document_did_open_message
    lsp_protocol_message({
      method: "textDocument/didOpen",
      jsonrpc: "2.0",
      params: {
        textDocument: {
          uri: "file:///Users/alexandresobolevski/src/github.com/Shopify/project-64k/src/snippets/product-card.liquid",
          version: 2,
          languageId: "liquid",
          text: "<html></html>",
        },
      },
    })
  end

  def lsp_protocol_message(obj)
    json = JSON.dump(obj)
    "Content-Length: #{json.size}\r\n\r\n#{json}"
  end
end
