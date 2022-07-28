# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DiagnosticsEngine
      include URIHelper

      attr_reader :storage

      def initialize(storage, bridge, diagnostics_manager = DiagnosticsManager.new)
        @diagnostics_lock = Mutex.new
        @diagnostics_manager = diagnostics_manager
        @storage = storage
        @bridge = bridge
      end

      def first_run?
        @diagnostics_manager.first_run?
      end

      def analyze_and_send_offenses(absolute_path_or_paths, config, force: false, only_single_file: false)
        return unless @diagnostics_lock.try_lock

        theme = ThemeCheck::Theme.new(storage)
        analyzer = ThemeCheck::Analyzer.new(theme, config.enabled_checks)

        if !only_single_file && (@diagnostics_manager.first_run? || force)
          run_full_theme_check(analyzer)
        else
          run_partial_theme_check(absolute_path_or_paths, theme, analyzer, only_single_file)
        end

        @diagnostics_lock.unlock
      end

      def clear_diagnostics(relative_paths)
        return unless @diagnostics_lock.try_lock

        as_array(relative_paths).each do |relative_path|
          send_clearing_diagnostics(relative_path)
        end

        @diagnostics_lock.unlock
      end

      private

      def run_full_theme_check(analyzer)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        token = @bridge.send_create_work_done_progress_request
        @bridge.send_work_done_progress_begin(token, "Full theme check")
        @bridge.log("Checking #{storage.root}")
        offenses = nil
        time = Benchmark.measure do
          offenses = analyzer.analyze_theme do |path, i, total|
            @bridge.send_work_done_progress_report(token, "#{i}/#{total} #{path}", (i.to_f / total * 100.0).to_i)
          end
        end
        end_message = "Found #{offenses.size} offenses in #{format("%0.2f", time.real)}s"
        @bridge.send_work_done_progress_end(token, end_message)
        @bridge.log(end_message)
        send_diagnostics(offenses)
      end

      def run_partial_theme_check(absolute_path_or_paths, theme, analyzer, only_single_file)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        relative_paths = as_array(absolute_path_or_paths).map do |absolute_path|
          Pathname.new(storage.relative_path(absolute_path))
        end

        theme_files = relative_paths
          .map { |relative_path| theme[relative_path] }
          .reject(&:nil?)

        deleted_relative_paths = relative_paths - theme_files.map(&:relative_path)
        deleted_relative_paths
          .each { |p| send_clearing_diagnostics(p) }

        token = @bridge.send_create_work_done_progress_request
        @bridge.send_work_done_progress_begin(token, "Partial theme check")
        offenses = nil
        time = Benchmark.measure do
          offenses = analyzer.analyze_files(theme_files, only_single_file: only_single_file) do |path, i, total|
            @bridge.send_work_done_progress_report(token, "#{i}/#{total} #{path}", (i.to_f / total * 100.0).to_i)
          end
        end
        end_message = "Found #{offenses.size} new offenses in #{format("%0.2f", time.real)}s"
        @bridge.send_work_done_progress_end(token, end_message)
        @bridge.log(end_message)
        send_diagnostics(offenses, theme_files.map(&:relative_path), only_single_file: only_single_file)
      end

      def send_clearing_diagnostics(relative_path)
        raise 'Unsafe operation' unless @diagnostics_lock.owned?

        relative_path = Pathname.new(relative_path) unless relative_path.is_a?(Pathname)
        @diagnostics_manager.clear_diagnostics(relative_path)
        send_diagnostic(relative_path, DiagnosticsManager::NO_DIAGNOSTICS)
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
        ).each do |relative_path, diagnostics|
          send_diagnostic(relative_path, diagnostics)
        end
      end

      def send_diagnostic(relative_path, diagnostics)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
        @bridge.send_notification('textDocument/publishDiagnostics', {
          uri: file_uri(storage.path(relative_path)),
          diagnostics: diagnostics.map(&:to_h),
        })
      end
    end
  end
end
