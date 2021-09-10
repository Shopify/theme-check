# frozen_string_literal: true

require "benchmark"

module ThemeCheck
  module LanguageServer
    class Handler
      include URIHelper
      include PositionHelper

      CAPABILITIES = {
        completionProvider: {
          triggerCharacters: ['.', '{{ ', '{% '],
          context: true,
        },
        documentLinkProvider: true,
        textDocumentSync: {
          openClose: true,
          change: TextDocumentSyncKind::INCREMENTAL,
          willSave: false,
          save: true,
        },
      }

      attr_reader :storage

      def initialize(server)
        @server = server
        @diagnostics_tracker = DiagnosticsTracker.new
        @storage = nil
      end

      def on_initialize(id, params)
        @root_path = root_path_from_params(params)

        # Tell the client we don't support anything if there's no rootPath
        return send_response(id, { capabilities: {} }) if @root_path.nil?
        @storage = in_memory_storage(@root_path)
        @completion_engine = CompletionEngine.new(@storage)
        @document_link_engine = DocumentLinkEngine.new(@storage)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#responseMessage
        send_response(id, {
          capabilities: CAPABILITIES,
        })
      end

      def on_exit(_id, _params)
        close!
      end
      alias_method :on_shutdown, :on_exit

      def on_text_document_did_change(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        content = @storage.read(relative_path)
        content_changes(params).each do |change|
          # We support incremental changes
          if (range = change.dig('range'))
            start_index = from_row_column_to_index(
              content,
              range.dig('start', 'line'),
              range.dig('start', 'character'),
            )
            end_index = from_row_column_to_index(
              content,
              range.dig('end', 'line'),
              range.dig('end', 'character'),
            )
            content[start_index..end_index] = change.dig('text')
          else
            content = change.dig('text')
          end
        end
        @storage.write(relative_path, content)
      end

      def on_text_document_did_close(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, "")
      end

      def on_text_document_did_open(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, text_document_text(params))
        analyze_and_send_offenses(text_document_uri(params)) if @diagnostics_tracker.first_run?
      end

      def on_text_document_did_save(_id, params)
        analyze_and_send_offenses(text_document_uri(params))
      end

      def on_text_document_document_link(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        send_response(id, document_links(relative_path))
      end

      def on_text_document_completion(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        line = params.dig('position', 'line')
        col = params.dig('position', 'character')
        send_response(id, completions(relative_path, line, col))
      end

      private

      def in_memory_storage(root)
        config = config_for_path(root)

        # Make a real FS to get the files from the snippets folder
        fs = ThemeCheck::FileSystemStorage.new(
          config.root,
          ignored_patterns: config.ignored_patterns
        )

        # Turn that into a hash of empty buffers
        files = fs.files
          .map { |fn| [fn, ""] }
          .to_h

        InMemoryStorage.new(files, config.root)
      end

      def text_document_uri(params)
        file_path(params.dig('textDocument', 'uri'))
      end

      def relative_path_from_text_document_uri(params)
        @storage.relative_path(text_document_uri(params))
      end

      def root_path_from_params(params)
        root_uri = params["rootUri"]
        root_path = params["rootPath"]
        if root_uri
          file_path(root_uri)
        elsif root_path
          root_path
        end
      end

      def text_document_text(params)
        params.dig('textDocument', 'text')
      end

      def content_changes(params)
        params.dig('contentChanges')
      end

      def config_for_path(path)
        root = ThemeCheck::Config.find(path) || @root_path
        ThemeCheck::Config.from_path(root)
      end

      def analyze_and_send_offenses(absolute_path)
        config = config_for_path(absolute_path)
        storage = ThemeCheck::FileSystemStorage.new(
          config.root,
          ignored_patterns: config.ignored_patterns
        )
        theme = ThemeCheck::Theme.new(storage)
        analyzer = ThemeCheck::Analyzer.new(theme, config.enabled_checks)

        if @diagnostics_tracker.first_run?
          # Analyze the full theme on first run
          log("Checking #{config.root}")
          offenses = nil
          time = Benchmark.measure do
            offenses = analyzer.analyze_theme
          end
          log("Found #{offenses.size} offenses in #{format("%0.2f", time.real)}s")
          send_diagnostics(offenses)
        else
          # Analyze selected files
          relative_path = Pathname.new(@storage.relative_path(absolute_path))
          file = theme[relative_path]
          # Skip if not a theme file
          if file
            log("Checking #{relative_path}")
            offenses = nil
            time = Benchmark.measure do
              offenses = analyzer.analyze_files([file])
            end
            log("Found #{offenses.size} new offenses in #{format("%0.2f", time.real)}s")
            send_diagnostics(offenses, [absolute_path])
          end
        end
      end

      def completions(relative_path, line, col)
        @completion_engine.completions(relative_path, line, col)
      end

      def document_links(relative_path)
        @document_link_engine.document_links(relative_path)
      end

      def send_diagnostics(offenses, analyzed_files = nil)
        @diagnostics_tracker.build_diagnostics(offenses, analyzed_files: analyzed_files) do |path, diagnostic_offenses|
          send_diagnostic(path, diagnostic_offenses)
        end
      end

      def send_diagnostic(path, offenses)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
        send_notification('textDocument/publishDiagnostics', {
          uri: file_uri(path),
          diagnostics: offenses.map { |offense| offense_to_diagnostic(offense) },
        })
      end

      def offense_to_diagnostic(offense)
        diagnostic = {
          code: offense.code_name,
          message: offense.message,
          range: range(offense),
          severity: severity(offense),
          source: "theme-check",
        }
        diagnostic["codeDescription"] = code_description(offense) unless offense.doc.nil?
        diagnostic
      end

      def code_description(offense)
        {
          href: offense.doc,
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

      def send_message(message)
        message[:jsonrpc] = '2.0'
        @server.send_response(message)
      end

      def send_response(id, result = nil, error = nil)
        message = { id: id }
        message[:result] = result if result
        message[:error] = error if error
        send_message(message)
      end

      def send_notification(method, params)
        message = { method: method }
        message[:params] = params
        send_message(message)
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
