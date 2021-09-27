# frozen_string_literal: true

require "benchmark"

module ThemeCheck
  module LanguageServer
    class Handler
      include URIHelper

      SERVER_INFO = {
        name: $PROGRAM_NAME,
        version: ThemeCheck::VERSION,
      }

      CAPABILITIES = {
        completionProvider: {
          triggerCharacters: ['.', '{{ ', '{% '],
          context: true,
        },
        documentLinkProvider: true,
        textDocumentSync: {
          openClose: true,
          change: TextDocumentSyncKind::FULL,
          willSave: false,
          save: true,
        },
      }

      def initialize(bridge)
        @bridge = bridge
      end

      def on_initialize(id, params)
        @root_path = root_path_from_params(params)

        # Tell the client we don't support anything if there's no rootPath
        return @bridge.send_response(id, { capabilities: {} }) if @root_path.nil?

        @bridge.supports_work_done_progress = params.dig('capabilities', 'window', 'workDoneProgress') || false
        @storage = in_memory_storage(@root_path)
        @completion_engine = CompletionEngine.new(@storage)
        @document_link_engine = DocumentLinkEngine.new(@storage)
        @diagnostics_engine = DiagnosticsEngine.new(@bridge)
        @bridge.send_response(id, {
          capabilities: CAPABILITIES,
          serverInfo: SERVER_INFO,
        })
      end

      def on_shutdown(id, _params)
        @bridge.send_response(id, nil)
      end

      def on_exit(_id, _params)
        close!
      end

      def on_text_document_did_change(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, content_changes_text(params))
      end

      def on_text_document_did_close(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, "")
      end

      def on_text_document_did_open(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, text_document_text(params))
        analyze_and_send_offenses(text_document_uri(params)) if @diagnostics_engine.first_run?
      end

      def on_text_document_did_save(_id, params)
        analyze_and_send_offenses(text_document_uri(params))
      end

      def on_text_document_document_link(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @bridge.send_response(id, @document_link_engine.document_links(relative_path))
      end

      def on_text_document_completion(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        line = params.dig('position', 'line')
        col = params.dig('position', 'character')
        @bridge.send_response(id, @completion_engine.completions(relative_path, line, col))
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

      def content_changes_text(params)
        params.dig('contentChanges', 0, 'text')
      end

      def config_for_path(path)
        root = ThemeCheck::Config.find(path) || @root_path
        ThemeCheck::Config.from_path(root)
      end

      def analyze_and_send_offenses(absolute_path)
        @diagnostics_engine.analyze_and_send_offenses(
          absolute_path,
          config_for_path(absolute_path)
        )
      end

      def log(message)
        @bridge.log(message)
      end

      def close!
        raise DoneStreaming
      end
    end
  end
end
