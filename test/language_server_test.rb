# frozen_string_literal: true
require "test_helper"
require "active_support/core_ext/hash/keys"

class LanguageServerTest < Minitest::Test
  def setup
    @in = StringIO.new
    @out = StringIO.new
    @err = StringIO.new

    @server = ThemeCheck::LanguageServer::Server.new(
      in_stream: @in,
      out_stream: @out,
      err_stream: @err
    )
  end

  OffenseMock = Struct.new(
    :code_name,
    :severity,
    :message,
    :template,
    :start_column,
    :end_column,
    :start_line,
    :end_line,
  ) do
    def self.build(path)
      new(
        'LiquidTag',
        :style,
        'Wrong',
        TemplateMock.new(path),
        5,
        14,
        9,
        9,
      )
    end
  end
  TemplateMock = Struct.new(:path)

  def test_sends_offenses_on_open
    theme = make_file_system_theme("layout/theme.liquid" => "")
    ThemeCheck::Analyzer.any_instance.stubs(:offenses).returns([
      OffenseMock.build(theme.all[0].path),
    ])

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootPath: theme.root,
      },
    }, {
      jsonrpc: "2.0",
      id: "123",
      method: "initialized",
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: "file://layout/theme.liquid",
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      method: "exit",
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: ThemeCheck::LanguageServer::Handler::CAPABILITIES,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: "file:#{theme.all[0].path}",
        diagnostics: [{
          range: {
            start: {
              line: 9,
              character: 5,
            },
            end: {
              line: 9,
              character: 14,
            },
          },
          severity: 3,
          code: "LiquidTag",
          source: "theme-check",
          message: "Wrong",
        }],
      },
    })
  end

  def test_sends_offenses_on_text_document_did_save
    theme = make_file_system_theme("layout/theme.liquid" => "")

    @server.handler.stubs(:analyze).returns([
      OffenseMock.build(theme.all[0].path),
    ])

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootPath: theme.root,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didSave",
      params: {
        textDocument: {
          uri: "file://layout/theme.liquid",
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      method: "exit",
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: ThemeCheck::LanguageServer::Handler::CAPABILITIES,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: "file:#{theme.all[0].path}",
        diagnostics: [{
          range: {
            start: {
              line: 9,
              character: 5,
            },
            end: {
              line: 9,
              character: 14,
            },
          },
          severity: 3,
          code: "LiquidTag",
          source: "theme-check",
          message: "Wrong",
        }],
      },
    })
  end

  def test_finds_root_from_file
    theme = make_file_system_theme(
      "src/layout/theme.liquid" => "",
      "src/.theme-check.yml" => "",
      ".theme-check.yml" => "",
    )

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootPath: theme.root,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: "file://" + theme.root.join("src/layout/theme.liquid").to_s,
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      method: "exit",
    })

    assert_includes(@err.string, "Checking #{theme.root.join('src')}")
  end

  def test_sends_empty_diagnostic_for_fixed_offences
    theme = make_file_system_theme(
      "layout/theme.liquid" => "",
      "templates/perfect.liquid" => "",
    )
    @server.handler.stubs(:analyze)
      .returns([
        OffenseMock.build(theme["layout/theme"].path),
      ])
      # On second analysis, no more offenses
      .then.returns([])

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootPath: theme.root,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didSave",
      params: {
        textDocument: {
          uri: "file://layout/theme.liquid",
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didSave",
      params: {
        textDocument: {
          uri: "file://layout/theme.liquid",
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      method: "exit",
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: ThemeCheck::LanguageServer::Handler::CAPABILITIES,
      },
    }, {
      # After first save, one offense
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: "file:#{theme.all[0].path}",
        diagnostics: [{
          range: {
            start: {
              line: 9,
              character: 5,
            },
            end: {
              line: 9,
              character: 14,
            },
          },
          severity: 3,
          code: "LiquidTag",
          source: "theme-check",
          message: "Wrong",
        }],
      },
    }, {
      # After second save, no more offenses, we return [] to clean up
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: "file:#{theme.all[0].path}",
        diagnostics: [],
      },
    })
  end

  private

  def send_messages(*messages)
    messages.each do |message|
      default = {
        jsonrpc: "2.0",
      }
      json = JSON.dump(default.merge(message))
      @in.puts("Content-Length: #{json.size}\r\n\r\n#{json}")
    end
    @in.rewind
    @server.listen
    @out.rewind
    @err.rewind
  end

  def assert_responses(*expected_responses)
    actual_responses = []
    scanner = StringScanner.new(@out.string)
    while scanner.scan_until(/Content-Length: (\d+)\r\n\r\n/)
      len = scanner[1].to_i
      body = scanner.peek(len)
      actual_responses << JSON.parse(body).deep_symbolize_keys
    end
    assert_equal(expected_responses, actual_responses)
  end
end
