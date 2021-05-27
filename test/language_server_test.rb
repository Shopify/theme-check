# frozen_string_literal: true
require "test_helper"

class LanguageServerTest < Minitest::Test
  def setup
    @in = StringIO.new
    @out = StringIO.new
    @err = StringIO.new

    @server = ThemeCheck::LanguageServer::Server.new(
      in_stream: @in,
      out_stream: @out,
      err_stream: @err,
      should_raise_errors: true
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
  CAPABILITIES = JSON.parse(JSON.generate(ThemeCheck::LanguageServer::Handler::CAPABILITIES))

  def test_sends_offenses_on_open
    storage = make_file_system_storage("layout/theme.liquid" => "")
    ThemeCheck::Analyzer.any_instance.stubs(:offenses).returns([
      OffenseMock.build(storage.path("layout/theme.liquid")),
    ])

    send_messages({
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialized",
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didOpen",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_responses({
      "jsonrpc" => "2.0",
      "id" => "123",
      "result" => {
        "capabilities" => CAPABILITIES,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/publishDiagnostics",
      "params" => {
        "uri" => "file://#{storage.path('layout/theme.liquid')}",
        "diagnostics" => [{
          "range" => {
            "start" => {
              "line" => 9,
              "character" => 5,
            },
            "end" => {
              "line" => 9,
              "character" => 14,
            },
          },
          "severity" => 3,
          "code" => "LiquidTag",
          "codeDescription" => {
            "href" => "https://path.to/docs.md",
          },
          "source" => "theme-check",
          "message" => "Wrong",
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
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didSave",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_responses({
      "jsonrpc" => "2.0",
      "id" => "123",
      "result" => {
        "capabilities" => CAPABILITIES,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/publishDiagnostics",
      "params" => {
        "uri" => "file://#{storage.path('layout/theme.liquid')}",
        "diagnostics" => [{
          "range" => {
            "start" => {
              "line" => 9,
              "character" => 5,
            },
            "end" => {
              "line" => 9,
              "character" => 14,
            },
          },
          "severity" => 3,
          "code" => "LiquidTag",
          "codeDescription" => {
            "href" => "https://path.to/docs.md",
          },
          "source" => "theme-check",
          "message" => "Wrong",
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
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didOpen",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path("src/layout/theme.liquid")}",
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_includes(@err.string, "Checking #{storage.path('src')}")
  end

  def test_document_link_response
    template = <<~LIQUID
      {% render 'a' %}
    LIQUID

    storage = make_file_system_storage

    send_messages({
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didOpen",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
          "text" => template,
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "textDocument/documentLink",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_responses_include({
      "jsonrpc" => "2.0",
      "id" => 1,
      "result" => [{
        "target" => "file://#{storage.path('snippets/a.liquid')}",
        "range" => {
          "start" => {
            "line" => 0,
            "character" => template.index('a'),
          },
          "end" => {
            "line" => 0,
            "character" => template.index('a') + 1,
          },
        },
      }],
    })
  end

  def test_document_links_from_correct_root
    template = <<~LIQUID
      {% render 'a' %}
    LIQUID

    storage = make_file_system_storage(
      ".theme-check.yml" => <<~CONFIG,
        root: src/theme
      CONFIG
    )

    send_messages({
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didOpen",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('src/theme/layout/theme.liquid')}",
          "text" => template,
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "textDocument/documentLink",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('src/theme/layout/theme.liquid')}",
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_responses_include({
      "jsonrpc" => "2.0",
      "id" => 1,
      "result" => [{
        "target" => "file://#{storage.path('src/theme/snippets/a.liquid')}",
        "range" => {
          "start" => {
            "line" => 0,
            "character" => template.index('a'),
          },
          "end" => {
            "line" => 0,
            "character" => template.index('a') + 1,
          },
        },
      }],
    })
  end

  def test_sends_empty_diagnostic_for_fixed_offenses
    storage = make_file_system_storage(
      "layout/theme.liquid" => "",
      "templates/perfect.liquid" => "",
    )
    ThemeCheck::Analyzer.any_instance.expects(:offenses)
      .twice
      .returns([
        OffenseMock.build(storage.path('layout/theme.liquid')),
      ])
      .then.returns([]) # On second analysis, no more offenses

    send_messages({
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => storage.root,
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didSave",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "textDocument/didSave",
      "params" => {
        "textDocument" => {
          "uri" => "file://#{storage.path('layout/theme.liquid')}",
          "version" => 1,
        },
      },
    }, {
      "jsonrpc" => "2.0",
      "method" => "exit",
    })

    assert_responses({
      "jsonrpc" => "2.0",
      "id" => "123",
      "result" => {
        "capabilities" => CAPABILITIES,
      },
    }, {
      # After first save, one offense
      "jsonrpc" => "2.0",
      "method" => "textDocument/publishDiagnostics",
      "params" => {
        "uri" => "file://#{storage.path('layout/theme.liquid')}",
        "diagnostics" => [{
          "range" => {
            "start" => {
              "line" => 9,
              "character" => 5,
            },
            "end" => {
              "line" => 9,
              "character" => 14,
            },
          },
          "severity" => 3,
          "code" => "LiquidTag",
          "codeDescription" => {
            "href" => "https://path.to/docs.md",
          },
          "source" => "theme-check",
          "message" => "Wrong",
        }],
      },
    }, {
      # After second save, no more offenses, we return [] to clean up
      "jsonrpc" => "2.0",
      "method" => "textDocument/publishDiagnostics",
      "params" => {
        "uri" => "file://#{storage.path('layout/theme.liquid')}",
        "diagnostics" => [],
      },
    })
  end

  def test_handles_on_initialize_with_null_paths
    send_messages({
      "jsonrpc" => "2.0",
      "id" => "123",
      "method" => "initialize",
      "params" => {
        "rootPath" => nil,
        "rootUri" => nil,
      },
    })

    assert_responses({
      "jsonrpc" => "2.0",
      "id" => "123",
      "result" => {
        "capabilities" => {},
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

  def responses
    actual_responses = []
    scanner = StringScanner.new(@out.string)
    while scanner.scan_until(/Content-Length: (\d+)\r\n\r\n/)
      len = scanner[1].to_i
      body = scanner.peek(len)
      actual_responses << JSON.parse(body)
    end
    actual_responses
  end

  def assert_responses(*expected_responses)
    actual_responses = responses
    expected_responses.each do |response|
      actual_response = actual_responses.shift
      assert_equal(response, actual_response, <<~ERR)
        Expected response:

        #{JSON.pretty_generate(response)}

        Actual response:

        #{JSON.pretty_generate(actual_response)}"
      ERR
    end
  end

  def assert_responses_include(*expected_responses)
    actual_responses = responses
    expected_responses.each do |response|
      assert(
        actual_responses.find { |actual| actual == response },
        <<~ERR,
          Expected to find the following object:

          #{JSON.pretty_generate(response)}

          in the following responses:

          #{JSON.pretty_generate(actual_responses)}"
        ERR
      )
    end
  end
end
