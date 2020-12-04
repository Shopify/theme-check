# frozen_string_literal: true
require 'test_helper'

describe LiquidLanguageServer::Router do
  before do
    @offense_factory = Minitest::Mock.new
    @router = LiquidLanguageServer::Router.new(@offense_factory)
  end

  it 'implements on_initialize' do
    call = @router.on_initialize(1, {})
    expected = {
      type: "response",
      id: 1,
      result: {
        capabilities: {
          textDocumentSync: 1,
        },
      },
    }

    assert_equal(call, expected)
  end

  it 'implements on_initialized' do
    call = @router.on_initialized(1, {})
    expected = {
      type: "log",
      message: 'initialized!',
    }

    assert_equal(call, expected)
  end

  it 'implements on_exit' do
    call = @router.on_exit(1, {})
    expected = {
      type: "exit",
    }

    assert_equal(call, expected)
  end

  it 'implements on_text_document_did_open that returns diagnostics' do
    path = '/some/path'
    params = {
      'textDocument' => {
        'uri' => "file://#{path}",
        'text' => '<html></html>',
      },
    }

    TemplateMock = Struct.new(:path)
    template_mock = TemplateMock.new(path)
    OffenseMock = Struct.new(
      :code_name,
      :severity,
      :message,
      :template,
      :start_column,
      :end_column,
      :start_line,
      :end_line,
    )
    offense = OffenseMock.new('LiquidTag', :style, 'Wrong', template_mock, 5, 14, 9, 9)
    @offense_factory.expect(:offenses, [offense], [path])

    call = @router.on_text_document_did_open(1, params)

    expected = {
      type: "notification",
      method: 'textDocument/publishDiagnostics',
      params: {
        uri: "file://#{path}",
        diagnostics: [
          {
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
            code: 'LiquidTag',
            source: 'theme-check',
            message: 'Wrong',
          },
        ],
      },
    }

    assert_equal(expected, call)
  end
end
