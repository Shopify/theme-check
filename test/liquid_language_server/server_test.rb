# frozen_string_literal: true
require "test_helper"
require 'tempfile'

class ServerTest < Minitest::Test
  def setup
    router = Struct.new(:send)
    @in = Tempfile.new('in')
    @out = Tempfile.new('out')
    @err = Tempfile.new('err')

    @server = LiquidLanguageServer::Server.new(
      router: router,
      in_stream: @in,
      out_stream: @out,
      err_stream: @err
    )
    @thread = Thread.new { @server.listen }
  end

  def teardown
    Thread.kill(@thread)
  end

  def test_passes
    message = JSON.dump({
      method: "textDocument/didOpen",
      jsonrpc: "2.0",
      params: {
        textDocument: {
          uri: "file:///Users/alexandresobolevski/src/github.com/Shopify/project-64k/src/snippets/product-card.liquid",
          version: 2,
          languageId: "liquid",
          text: "<html></html>"
        }
      }
    })

    @in.puts("Content-Length: #{message.size}\r\n\r\n#{message}")
    # puts(@in.gets)
    # puts(@out.gets)
    puts "hola"
    puts(@err.gets)
  end
end