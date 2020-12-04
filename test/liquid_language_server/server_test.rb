# frozen_string_literal: true
require 'test_helper'
require 'stringio'

describe LiquidLanguageServer::Server do
  before do
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

  it 'raises an exception if one of the provided io steams is incompatible' do
    [
      Proc.new { LiquidLanguageServer::Server.new(router: @router, in_stream: :not_io) },
      Proc.new { LiquidLanguageServer::Server.new(router: @router, out_stream: :not_io) },
      Proc.new { LiquidLanguageServer::Server.new(router: @router, err_stream: :not_io) },
    ].each do |invalid_instantiation|
      assert_raises(LiquidLanguageServer::IncompatibleStream) do 
        invalid_instantiation.call
      end.message.match?(/in_stream, out_stream, and err_stream must be a kind of/)
    end
  end

  it 'turns responses into valid responses' do
    @router.expect(
      :on_text_document_did_open,
      {
        type: 'notification',
        method: 'hello_world',
        params: [],
      },
      [nil, Hash],
    )

    send_message(build_payload)

    assert_equal(
      "Content-Length: 52\r\n\r\n{\"jsonrpc\":\"2.0\",\"method\":\"hello_world\",\"params\":[]}",
      @out.string,
    )
  end

  it 'turns notifications into valid notifications' do
    @router.expect(
      :on_text_document_did_open,
      {
        type: 'response',
        id: 1,
        result: {},
      },
      [nil, Hash],
    )

    send_message(build_payload)

    assert_equal(
      "Content-Length: 36\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{}}",
      @out.string,
    )
  end

  it 'logs when initialized and when done' do
    @router.expect(
      :on_initialized,
      {
        type: 'log',
        id: nil,
        result: nil,
        message: 'initialized!',
      },
      [nil, Hash],
    )

    send_message(build_payload({ method: 'initialized', params: {} }))

    assert_equal(
      "#{JSON.dump({ message: 'initialized!' })}\n#{JSON.dump({ message: 'Done streamin\'!' })}\n",
      @err.string,
    )
  end

  it 'prints an error when router does not handle method' do
    @router.expect(
      :on_initialized,
      {
        type: 'log',
        id: nil,
        result: nil,
        message: 'initialized!',
      },
      [nil, Hash],
    )

    send_message(build_payload({ method: 'zipf law' }))

    assert_equal(
      "#{JSON.dump({ message: 'ROUTER DOES NOT RESPOND TO on_zipf_law' })}\n#{JSON.dump({ message: 'Done streamin\'!' })}\n",
      @err.string,
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

  def build_payload(args = {})
    default_params = {
      textDocument: {
        uri: "file:///Users/alexandresobolevski/src/github.com/Shopify/project-64k/src/snippets/product-card.liquid",
        version: 2,
        languageId: "liquid",
        text: "<html></html>",
      },
    }

    as_lsp_protocol_message({
      method: args[:method] || "textDocument/didOpen",
      jsonrpc: "2.0",
      params: args[:params] || default_params,
    })
  end

  def as_lsp_protocol_message(obj)
    json = JSON.dump(obj)
    "Content-Length: #{json.size}\r\n\r\n#{json}"
  end
end
