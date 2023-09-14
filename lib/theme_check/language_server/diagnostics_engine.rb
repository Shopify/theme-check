# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DiagnosticsEngine
      include URIHelper

      def initialize(workspace, bridge, diagnostics_manager = DiagnosticsManager.new)
        @diagnostics_lock = Mutex.new
        @diagnostics_manager = diagnostics_manager
        @workspace = workspace
        @bridge = bridge
      end

      def first_run?
        @diagnostics_manager.first_run?
      end

      def analyze_and_send_offenses(absolute_path_or_paths, config, force: false, only_single_file: false)
        absolute_paths = as_array(absolute_path_or_paths)
        groups = @workspace.group_paths_by_theme_view(absolute_paths)
        @bridge.log("Analyzing offenses in themes #{groups.map(&:first).map!(&:root).join(', ')}")

        groups.each do |theme_view, paths|
          break unless @diagnostics_lock.try_lock

          theme = ThemeCheck::Theme.new(theme_view)
          analyzer = ThemeCheck::Analyzer.new(theme, config.enabled_checks)

          @bridge.log("#{only_single_file} - #{@diagnostics_manager.first_run?} - #{force}")

          if !only_single_file && (@diagnostics_manager.first_run? || force)
            run_full_theme_check(theme, analyzer)
          else
            theme_files = clear_unknown_relative_paths(paths, theme)
            run_partial_theme_check(theme_files, theme, analyzer, only_single_file)
          end

          @diagnostics_lock.unlock
        end
      end

      def clear_diagnostics(relative_paths)
        return unless @diagnostics_lock.try_lock

        as_array(relative_paths).each do |relative_path|
          send_clearing_diagnostics(relative_path)
        end

        @diagnostics_lock.unlock
      end

      private

      def run_full_theme_check(theme, analyzer)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        token = @bridge.send_create_work_done_progress_request
        @bridge.send_work_done_progress_begin(token, "Full theme check")
        @bridge.log("Full Check #{theme.storage.root}")
        offenses = nil
        time = Benchmark.measure do
          offenses = analyzer.analyze_theme do |path, i, total|
            send_work_done_progress_report(token, path, i, total)
          end
        end
        end_message = "Found #{offenses.size} offenses in #{format("%0.2f", time.real)}s"
        @bridge.send_work_done_progress_end(token, end_message)
        @bridge.log(end_message)
        send_diagnostics(offenses)
      end

      def run_partial_theme_check(theme_files, theme, analyzer, only_single_file)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        token = @bridge.send_create_work_done_progress_request
        @bridge.send_work_done_progress_begin(token, "Partial theme check")
        @bridge.log("Partial Check #{theme.storage.root} #{theme_files.map(&:relative_path).join(', ')})}")
        offenses = nil
        time = Benchmark.measure do
          offenses = analyzer.analyze_files(theme_files, only_single_file: only_single_file) do |path, i, total|
            send_work_done_progress_report(token, path, i, total)
          end
        end
        end_message = "Found #{offenses.size} new offenses in #{format("%0.2f", time.real)}s"
        @bridge.send_work_done_progress_end(token, end_message)
        @bridge.log(end_message)
        send_diagnostics(offenses, theme_files.map(&:workspace_path), only_single_file: only_single_file)
      end

      def send_work_done_progress_report(token, path, i, total)
        @bridge.send_work_done_progress_report(token, "#{i}/#{total} #{path}", (i.to_f / total * 100.0).to_i)
      end

      def clear_unknown_relative_paths(absolute_paths, theme)
        relative_paths = absolute_paths.map do |absolute_path|
          Pathname.new(theme.storage.relative_path(absolute_path))
        end

        theme_files = relative_paths
          .map { |relative_path| theme[relative_path] }
          .reject(&:nil?)

        deleted_relative_paths = relative_paths - theme_files.map(&:relative_path)
        deleted_relative_paths.each do |relative_path|
          send_clearing_diagnostics(theme.storage.workspace_path(relative_path))
        end

        theme_files
      end

      def send_clearing_diagnostics(workspace_path)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        workspace_path = Pathname.new(workspace_path) unless workspace_path.is_a?(Pathname)
        @diagnostics_manager.clear_diagnostics(workspace_path)
        send_diagnostic(workspace_path, DiagnosticsManager::NO_DIAGNOSTICS)
      end

      def as_array(maybe_array)
        case maybe_array
        when Array
          maybe_array
        else
          [maybe_array]
        end
      end

      def send_diagnostics(offenses, analyzed_files = nil, only_single_file: false)
        @diagnostics_manager.build_diagnostics(
          offenses,
          analyzed_files: analyzed_files,
          only_single_file: only_single_file
        ).each do |workspace_path, diagnostics|
          send_diagnostic(workspace_path, diagnostics)
        end
      end

      def send_diagnostic(workspace_path, diagnostics)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
        @bridge.send_notification('textDocument/publishDiagnostics', {
          uri: file_uri(@workspace.path(workspace_path)),
          diagnostics: diagnostics.map(&:to_h),
        })
      end
    end
  end
end
