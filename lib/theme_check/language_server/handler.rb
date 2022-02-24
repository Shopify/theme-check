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
        codeActionProvider: {
          codeActionKinds: CodeActionProvider.all.map(&:kind),
          resolveProvider: false,
          workDoneProgress: false,
        },
        documentLinkProvider: true,
        executeCommandProvider: {
          workDoneProgress: false,
          commands: ExecuteCommandProvider.all.map(&:command),
        },
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

        @client_capabilities = ClientCapabilities.new(params.dig(:capabilities) || {})
        @configuration = Configuration.new(@bridge, @client_capabilities)
        @bridge.supports_work_done_progress = @client_capabilities.supports_work_done_progress?
        @storage = in_memory_storage(@root_path)
        @diagnostics_manager = DiagnosticsManager.new
        @completion_engine = CompletionEngine.new(@storage)
        @document_link_engine = DocumentLinkEngine.new(@storage)
        @diagnostics_engine = DiagnosticsEngine.new(@storage, @bridge, @diagnostics_manager)
        @execute_command_engine = ExecuteCommandEngine.new
        @execute_command_engine << CorrectionExecuteCommandProvider.new(@storage, @bridge, @diagnostics_manager)
        @execute_command_engine << RunChecksExecuteCommandProvider.new(@diagnostics_engine, @root_path, config_for_path(@root_path))
        @code_action_engine = CodeActionEngine.new(@storage, @diagnostics_manager)
        @bridge.send_response(id, {
          capabilities: CAPABILITIES,
          serverInfo: SERVER_INFO,
        })
      end

      def on_initialized(_id, _params)
        return unless @configuration
        @configuration.fetch
        @configuration.register_did_change_capability
      end

      def on_shutdown(id, _params)
        @bridge.send_response(id, nil)
      end

      def on_exit(_id, _params)
        close!
      end

      def on_text_document_did_open(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, text_document_text(params), text_document_version(params))
        analyze_and_send_offenses(text_document_uri(params)) if @configuration.check_on_open?
      end

      def on_text_document_did_change(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @storage.write(relative_path, content_changes_text(params), text_document_version(params))
        analyze_and_send_offenses(text_document_uri(params), only_single_file: true) if @configuration.check_on_change?
      end

      def on_text_document_did_close(_id, params)
        relative_path = relative_path_from_text_document_uri(params)
        file_system_content = Pathname.new(text_document_uri(params)).read(mode: 'rb', encoding: 'UTF-8')
        # On close, the file system becomes the source of truth
        @storage.write(relative_path, file_system_content, nil)
      end

      def on_text_document_did_save(_id, params)
        analyze_and_send_offenses(text_document_uri(params)) if @configuration.check_on_save?
      end

      def on_text_document_document_link(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        @bridge.send_response(id, @document_link_engine.document_links(relative_path))
      end

      def on_text_document_completion(id, params)
        relative_path = relative_path_from_text_document_uri(params)
        line = params.dig(:position, :line)
        col = params.dig(:position, :character)
        @bridge.send_response(id, @completion_engine.completions(relative_path, line, col))
      end

      def on_text_document_code_action(id, params)
        absolute_path = text_document_uri(params)
        start_position = range_element(params, :start)
        end_position = range_element(params, :end)
        only_code_action_kinds = params.dig(:context, :only) || []
        @bridge.send_response(id, @code_action_engine.code_actions(
          absolute_path,
          start_position,
          end_position,
          only_code_action_kinds,
        ))
      end

      def on_workspace_execute_command(id, params)
        @bridge.send_response(id, @execute_command_engine.execute(
          params[:command],
          params[:arguments],
        ))
      end

      def on_workspace_did_change_configuration(_id, _params)
        @configuration.fetch(force: true)
      end

      private

      def in_memory_storage(root)
        config = config_for_path(root)

        # Make a real FS to get the files from the snippets folder
        fs = ThemeCheck::FileSystemStorage.new(
          config.root,
          ignored_patterns: config.ignored_patterns
        )

        # Turn that into a hash of buffers
        files = fs.files
          .map { |fn| [fn, fs.read(fn)] }
          .to_h

        VersionedInMemoryStorage.new(files, config.root)
      end

      def text_document_uri(params)
        file_path(params.dig(:textDocument, :uri))
      end

      def relative_path_from_text_document_uri(params)
        @storage.relative_path(text_document_uri(params))
      end

      def root_path_from_params(params)
        root_uri = params[:rootUri]
        root_path = params[:rootPath]
        if root_uri
          file_path(root_uri)
        elsif root_path
          root_path
        end
      end

      def text_document_text(params)
        params.dig(:textDocument, :text)
      end

      def text_document_version(params)
        params.dig(:textDocument, :version)
      end

      def content_changes_text(params)
        params.dig(:contentChanges, 0, :text)
      end

      def config_for_path(path)
        root = ThemeCheck::Config.find(path) || @root_path
        ThemeCheck::Config.from_path(root)
      end

      def analyze_and_send_offenses(absolute_path, only_single_file: nil)
        @diagnostics_engine.analyze_and_send_offenses(
          absolute_path,
          config_for_path(absolute_path),
          only_single_file: only_single_file.nil? ? @configuration.only_single_file? : only_single_file
        )
      end

      def range_element(params, start_or_end)
        [
          params.dig(:range, start_or_end, :line),
          params.dig(:range, start_or_end, :character),
        ]
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
