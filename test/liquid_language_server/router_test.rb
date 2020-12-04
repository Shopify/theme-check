# frozen_string_literal: true
require 'test_helper'

describe LiquidLanguageServer::Router do
  before do
    @router = LiquidLanguageServer::Router.new
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
      method: 'initialized!',
    }

    assert_equal(call, expected)
  end

  it 'implements on_exit' do
    call = @router.on_exit
    expected = {
      type: "exit",
    }

    assert_equal(call, expected)
  end

  it 'implements on_text_document_did_open that returns diagnistics' do
    path = '/Users/alexandresobolevski/src/github.com/Shopify/project-64k/src/snippets/product-card.liquid'
    params = {
      'textDocument' => {
        'uri' => "file://#{path}",
        'text' => '<html></html>',
      },
    }

    TemplateMock = Struct.new(:path)
    template_mock = TemplateMock.new(path)

    OffenseMock = Struct.new(
      :code,
      :severity,
      :message,
      :template,
      :line_number,
      :start_column,
      :end_column
    )
    offense = OffenseMock.new('LiquidTag', :style, 'Wrong', template_mock, 10, 5, 15)

    ThemeCheck::Analyzer.any_instance.expects(:analyze_theme).returns(nil)
    ThemeCheck::Analyzer.any_instance.expects(:offenses).returns([offense])

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
