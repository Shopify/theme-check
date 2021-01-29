# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Handler
      CAPABILITIES = {
        textDocumentSync: {
          openClose: true,
          change: false,
          willSave: false,
          save: true,
        },
      }

      def initialize(server)
        @server = server
      end

      def on_initialize(id, params)
        @root_path = params["rootPath"]
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#responseMessage
        send_response(
          id: id,
          result: {
            capabilities: CAPABILITIES,
          }
        )
      end

      def on_exit(_id, _params)
        close!
      end

      def on_text_document_did_open(_id, params)
        analyze_and_send_offenses(params.dig('textDocument', 'uri').sub('file://', ''))
      end
      alias_method :on_text_document_did_save, :on_text_document_did_open

      private

      def analyze_and_send_offenses(file_path)
        root = ThemeCheck::Config.find(file_path) || @root_path
        config = ThemeCheck::Config.from_path(root)
        theme = ThemeCheck::Theme.new(config.root, ignored_patterns: config.ignored_patterns)
        analyzer = ThemeCheck::Analyzer.new(theme, config.enabled_checks)

        log("Checking #{config.root}")
        analyzer.analyze_theme
        log("Found #{theme.all.size} templates, and #{analyzer.offenses.size} offenses")
        send_diagnostics(analyzer.offenses, theme.all)
      end

      def send_diagnostics(offenses, templates)
        contains_offenses = []

        offenses.group_by(&:template).each do |template, template_offenses|
          next unless template
          send_diagnostic(template.path, template_offenses)
          contains_offenses.push(template.path)
        end

        # Publish diagnostics with empty array if template does not contain error
        templates.select { |t| !contains_offenses.include?(t.path) }.each do |template|
          send_diagnostic(template.path, [])
        end
      end

      def send_diagnostic(path, offenses)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
        send_response(
          method: 'textDocument/publishDiagnostics',
          params: {
            uri: "file:#{path}",
            diagnostics: offenses.map { |offense| offense_to_diagnostic(offense) },
          },
        )
      end

      def offense_to_diagnostic(offense)
        {
          range: range(offense),
          severity: severity(offense),
          code: offense.code_name,
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

      def send_response(message)
        message[:jsonrpc] = '2.0'
        @server.send_response(message)
      end

      def log(message)
        @server.log(message)
      end

      def close!
        raise DoneStreaming
      end
    end
  end
end
