# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Handler
      def initialize(server)
        @server = server
      end

      def on_initialize(id, params)
        root_path = params["rootPath"]
        @config = ThemeCheck::Config.from_path(root_path)
        @theme = ThemeCheck::Theme.new(@config.root)
        @analyzer = ThemeCheck::Analyzer.new(@theme, @config.enabled_checks)

        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#responseMessage
        send_response(
          id: id,
          result: {
            capabilities: {
              textDocumentSync: {
                openClose: false,
                change: false,
                willSave: false,
                save: true,
              },
            },
          }
        )
      end

      def on_initialized(_id, _params)
        log("Checking #{@config.root}")
        log("Found #{@theme.all.size} templates")
        @analyzer.analyze_theme
        log("Found #{@analyzer.offenses.size} offenses")
        send_offenses
      end

      def on_exit(_id, _params)
        close!
      end

      def on_text_document_did_save(_id, _params)
        @analyzer.analyze_theme
        send_offenses
      end

      private

      def send_offenses
        @analyzer.offenses.group_by(&:template).each do |template, offenses|
          next unless template
          # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
          send_response(
            method: 'textDocument/publishDiagnostics',
            params: {
              uri: "file:#{template.path}",
              diagnostics: offenses.map { |offense| offense_to_diagnostic(offense) },
            },
          )
        end
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
