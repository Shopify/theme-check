# frozen_string_literal: true

require "test_helper"

class LanguageServerTest < Minitest::Test
  include ThemeCheck::LanguageServer::URIHelper

  def setup
    @messenger = MockMessenger.new

    @server = ThemeCheck::LanguageServer::Server.new(
      messenger: @messenger,
      should_raise_errors: true,
      number_of_threads: 1
    )
  end

  OffenseMock = Struct.new(
    :code_name,
    :severity,
    :message,
    :theme_file,
    :start_column,
    :end_column,
    :start_row,
    :end_row,
    :doc,
    :whole_theme?,
  ) do
    def single_file?
      !whole_theme?
    end

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
        "https://path.to/docs.md",
        true,
      )
    end
  end
  TemplateMock = Struct.new(:path)

  # Stringify keys
  CAPABILITIES = ThemeCheck::LanguageServer::Handler::CAPABILITIES
  SERVER_INFO = ThemeCheck::LanguageServer::Handler::SERVER_INFO

  def test_sends_offenses_on_open
    storage = make_file_system_storage("layout/theme.liquid" => "")
    ThemeCheck::Analyzer.any_instance.stubs(:offenses).returns([
      OffenseMock.build(storage.path("layout/theme.liquid")),
    ])

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
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
          uri: file_uri(storage.path('layout/theme.liquid')),
          version: 1,
        },
      },
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: CAPABILITIES,
        serverInfo: SERVER_INFO,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: file_uri(storage.path('layout/theme.liquid')),
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
          codeDescription: {
            href: "https://path.to/docs.md",
          },
          source: "theme-check",
          message: "Wrong",
        }],
      },
    })
  end

  def test_sends_offenses_on_text_document_did_save
    storage = make_file_system_storage("layout/theme.liquid" => "")

    ThemeCheck::Analyzer.any_instance.expects(:offenses).returns([
      OffenseMock.build(storage.path("layout/theme.liquid")),
    ])

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didSave",
      params: {
        textDocument: {
          uri: file_uri(storage.path('layout/theme.liquid')),
          version: 1,
        },
      },
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: CAPABILITIES,
        serverInfo: SERVER_INFO,
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: {
        uri: file_uri(storage.path('layout/theme.liquid')),
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
          codeDescription: {
            href: "https://path.to/docs.md",
          },
          source: "theme-check",
          message: "Wrong",
        }],
      },
    })
  end

  def test_finds_root_from_file
    storage = make_file_system_storage(
      "src/layout/theme.liquid" => "",
      "src/.theme-check.yml" => "",
      ".theme-check.yml" => "",
    )

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: file_uri(storage.path("src/layout/theme.liquid")),
          version: 1,
        },
      },
    })

    assert_includes(@messenger.logs.join("\n"), "Checking #{storage.path('src')}")
  end

  def test_document_link_response
    contents = <<~LIQUID
      {% render 'a' %}
    LIQUID

    storage = make_file_system_storage

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: file_uri(storage.path('layout/theme.liquid')),
          text: contents,
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      id: 1,
      method: "textDocument/documentLink",
      params: {
        textDocument: {
          uri: file_uri(storage.path('layout/theme.liquid')),
        },
      },
    })

    assert_responses_include({
      jsonrpc: "2.0",
      id: 1,
      result: [{
        target: file_uri(storage.path('snippets/a.liquid')),
        range: {
          start: {
            line: 0,
            character: contents.index('a'),
          },
          end: {
            line: 0,
            character: contents.index('a') + 1,
          },
        },
      }],
    })
  end

  def test_document_links_from_correct_root
    contents = <<~LIQUID
      {% render 'a' %}
    LIQUID

    storage = make_file_system_storage(
      ".theme-check.yml" => <<~CONFIG,
        root: src/theme
      CONFIG
    )

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: file_uri(storage.path('src/theme/layout/theme.liquid')),
          text: contents,
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      id: 1,
      method: "textDocument/documentLink",
      params: {
        textDocument: {
          uri: file_uri(storage.path('src/theme/layout/theme.liquid')),
        },
      },
    })

    assert_responses_include({
      jsonrpc: "2.0",
      id: 1,
      result: [{
        target: file_uri(storage.path('src/theme/snippets/a.liquid')),
        range: {
          start: {
            line: 0,
            character: contents.index('a'),
          },
          end: {
            line: 0,
            character: contents.index('a') + 1,
          },
        },
      }],
    })
  end

  def test_handles_on_initialize_with_null_paths
    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootPath: nil,
        rootUri: nil,
      },
    })

    assert_responses({
      jsonrpc: "2.0",
      id: "123",
      result: {
        capabilities: {},
      },
    })
  end

  # This is a repetition of the document_links test but with a path that is URL encoded the same way
  # that VS Code would URL encode it (spaces to %20, and so on.)
  def test_handles_encoded_uris
    contents = <<~LIQUID
      {% render 'a' %}
    LIQUID

    storage = make_file_system_storage(
      ".theme-check.yml" => <<~YAML,
        root: "path with spaces/"
      YAML
    )

    send_messages({
      jsonrpc: "2.0",
      id: "123",
      method: "initialize",
      params: {
        rootUri: file_uri(storage.root),
      },
    }, {
      jsonrpc: "2.0",
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: file_uri(storage.path('path with spaces/layout/theme.liquid')),
          text: contents,
          version: 1,
        },
      },
    }, {
      jsonrpc: "2.0",
      id: 1,
      method: "textDocument/documentLink",
      params: {
        textDocument: {
          uri: file_uri(storage.path('path with spaces/layout/theme.liquid')),
        },
      },
    })

    assert_responses_include({
      jsonrpc: "2.0",
      id: 1,
      result: [{
        target: file_uri(storage.path('path with spaces/snippets/a.liquid')),
        range: {
          start: {
            line: 0,
            character: contents.index('a'),
          },
          end: {
            line: 0,
            character: contents.index('a') + 1,
          },
        },
      }],
    })
  end

  private

  def send_messages(*messages)
    messages << {
      jsonrpc: "2.0",
      method: "exit",
    }
    messages.each do |message|
      @messenger.send_mock_message(JSON.dump(message))
    end
    status_code = @server.listen
    assert_equal(0, status_code, "@server exited with error")
  end

  def assert_responses_include(*expected_responses)
    actual_responses = @messenger.sent_messages
    expected_responses.each do |response|
      assert(
        actual_responses.find { |actual| actual == response },
        <<~ERR,
          Expected to find the following object:

          #{JSON.pretty_generate(response)}

          in the following responses:

          #{JSON.pretty_generate(actual_responses)}

        ERR
      )
    end
  end
  alias_method :assert_responses, :assert_responses_include
end
