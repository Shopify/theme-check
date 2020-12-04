# frozen_string_literal: true
require "theme_check"

module LiquidLanguageServer
  class Router
    def initialize
      # do we need anything?
    end

    def on_initialize(id, _params)
      {
        type: "response",
        id: id,
        result: {
          capabilities: {
            textDocumentSync: 1,
          },
        },
      }
    end

    def on_initialized(_id, _params)
      {
        type: "log",
        method: "initialized!",
      }
    end

    def on_exit
      {
        type: "exit",
      }
    end

    def on_textDocument_didOpen(_id, params)
      text_document = params['textDocument']
      uri = text_document['uri']
      text = text_document['text']
      offenses = analyze(uri.sub('file://', ''))
      prepare_diagnostics(uri, text, offenses)
    end

    def on_textDocument_didSave(_id, _params)
      {}
    end

    private

    def prepare_diagnostics(uri, _text, offenses)
      # hash = @project_manager.update_document_content(uri, text)
      {
        type: "notification",
        method: 'textDocument/publishDiagnostics',
        params: {
          uri: uri,
          diagnostics: offenses.map { |offense| offense_to_diagnostic(offense) },
        },
      }
    end

    def analyze(file_path)
      theme = ThemeCheck::Theme.new(
        # Assuming file is in project/folder/file, we want project.
        File.dirname(File.dirname(file_path))
      )

      if theme.all.empty?
        abort("No templates found for #{file_path} \nusage: theme-check /path/to/your/project-64k")
      end

      analyzer = ThemeCheck::Analyzer.new(theme)
      analyzer.analyze_theme
      analyzer.offenses
      # offenses.reject! { |offense| offense.template.path.to_s != file_path }
    end

    def offense_to_diagnostic(offense)
      {
        range: range(offense),
        severity: severity(offense),
        code: offense.code,
        source: "theme-check",
        message: offense.message,
      }
    end

    def severity(offense)
      case offense.severity
      when :error
        1
      when :suggestion
        2
      when :style
        3
      else
        4
      end
    end

    def range(offense)
      {
        start: {
          line: offense.start_line,
          character: offense.start_column,
        },
        end: {
          line: offense.end_line,
          character: offense.end_column,
        },
      }
    end
  end
end
