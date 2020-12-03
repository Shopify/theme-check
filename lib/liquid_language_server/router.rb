# frozen_string_literal: true
require "theme_check"

module LiquidLanguageServer
  class Router
    def initialize
      # do we need anything?
    end

    def on_initialize(id, params)
      {
        type: "response",
        id: id,
        result: {
          capabilities: {
            textDocumentSync: 1
            # hoverProvider: false,
            # signatureHelpProvider: {
            #   triggerCharacters: ['(', ',']
            # },
            # definitionProvider: true,
            # referencesProvider: true,
            # documentSymbolProvider: true,
            # workspaceSymbolProvider: true,
            # xworkspaceReferencesProvider: true,
            # xdefinitionProvider: true,
            # xdependenciesProvider: true,
            # completionProvider: {
            #   resolveProvider: true,
            #   triggerCharacters: ['.', '::']
            # },
            # codeActionProvider: true,
            # renameProvider: true,
            # executeCommandProvider: {
            #   commands: []
            # },
            # xpackagesProvider: true
          }
        }
      }
    end

    def on_initialized(id, params)
      {
        type: "log",
        message: "initialized!"
      }
    end

    def on_exit()
      {
        type: "exit"
      }
    end

    def on_textDocument_didOpen(id, params)
      textDocument = params['textDocument']
      uri = textDocument['uri']
      text = textDocument['text']
      offences = analyze(uri.sub('file://', ''))
      prepare_diagnostics(uri, text, offences)
    end

    def on_textDocument_didSave(id, params)
      {}
    end

    private

    def prepare_diagnostics(uri, text, offences)
      # hash = @project_manager.update_document_content(uri, text)
      {
        type: "notification",
        message: 'textDocument/publishDiagnostics',
        params: {
          uri: uri,
          diagnostics: offences.map { |offence| offence_to_diagnostic(offence) },
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
      analyzer.offenses.reject! { |offense| offense.template.path.to_s != file_path }
    end

    def offence_to_diagnostic(offence)
      {
        range: range(offence),
        severity: severity(offence),
        code: offence.code,
        source: "theme-check",
        message: offence.message,
      }
    end

    def severity(offence)
      case offence.severity
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

    def range(offence)
      {
        start: {
          line: offence.line_number - 1,
          character: offence.start_column,
        },
        end: {
          line: offence.line_number - 1,
          character: offence.end_column - 1,
        },
      }
    end
  end
end
