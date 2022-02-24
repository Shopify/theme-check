# frozen_string_literal: true
require "logger"

module ThemeCheck
  module LanguageServer
    class DiagnosticsManager
      # This class exists to facilitate LanguageServer diagnostics tracking.
      #
      # Motivations:
      #   1. The first time we lint, we want all the errors from all the files.
      #   2. If we fix all the errors in a file, we have to send an empty array for that file.
      #   3. If we do a partial check, we should consider the whole theme diagnostics as valid, and return cached results
      #   4. We should be able to create WorkspaceEdits from diagnostics, so that the ExecuteCommandEngine can do its job
      #   5. We should clean up diagnostics that were applied by the client
      def initialize
        @latest_diagnostics = {} # { [Pathname(relative_path)] => Diagnostic[] }
        @mutex = Mutex.new
        @first_run = true
      end

      def first_run?
        @first_run
      end

      def diagnostics(relative_path)
        relative_path = Pathname.new(relative_path) if relative_path.is_a?(String)
        @mutex.synchronize { @latest_diagnostics[relative_path] || [] }
      end

      def build_diagnostics(offenses, analyzed_files: nil, only_single_file: false)
        @mutex.synchronize do
          full_check = analyzed_files.nil?
          analyzed_paths = analyzed_files.map { |path| Pathname.new(path) } unless full_check

          # When analyzed_files is nil, contains all offenses.
          # When analyzed_files is !nil, contains all whole theme offenses and single file offenses of the analyzed_files.
          current_diagnostics = offenses
            .select(&:theme_file)
            .group_by(&:theme_file)
            .transform_keys { |theme_file| Pathname.new(theme_file.relative_path) }
            .transform_values do |theme_file_offenses|
              theme_file_offenses.map { |o| Diagnostic.new(o) }
            end

          previous_paths = paths(@latest_diagnostics)
          current_paths = paths(current_diagnostics)

          diagnostics_update = (current_paths + previous_paths).map do |path|
            # When doing single file checks, we keep the whole theme old
            # ones and accept the new single ones
            if only_single_file && analyzed_paths.include?(path)
              single_file_diagnostics = current_diagnostics[path] || []
              whole_theme_diagnostics = whole_theme_diagnostics(path) || []
              [path, single_file_diagnostics + whole_theme_diagnostics]

            # If doing single file checks that are not in the
            # analyzed_paths array then we just keep the old
            # diagnostics
            elsif only_single_file
              [path, previous_diagnostics(path) || []]

            # When doing a full_check, we either send the current
            # diagnostics or an empty array to clear the diagnostics
            # for that file.
            elsif full_check
              [path, current_diagnostics[path] || []]

            # When doing a partial check, the single file diagnostics
            # from the previous runs should be sent. Otherwise the
            # latest results are the good ones.
            else
              new_diagnostics = current_diagnostics[path] || []
              should_use_cached_results = !analyzed_paths.include?(path)
              old_diagnostics = should_use_cached_results ? single_file_diagnostics(path) : []
              [path, new_diagnostics + old_diagnostics]
            end
          end.to_h

          @latest_diagnostics = diagnostics_update
            .reject { |_, v| v.empty? }

          @first_run = false

          # Only send updates for the current file when running with only_single_file
          diagnostics_update
            .reject { |p, _| only_single_file && !analyzed_paths.include?(p) }
        end
      end

      def workspace_edit(diagnostics)
        diagnostics = sanitize(diagnostics)
          .select(&:correctable?)

        {
          documentChanges: document_changes(diagnostics),
        }
      end

      def delete_applied(diagnostics)
        diagnostics = sanitize(diagnostics)
          .select(&:correctable?)

        previous_paths = paths(@latest_diagnostics)

        diagnostics.each do |diagnostic|
          delete(diagnostic.relative_path, diagnostic)
        end

        current_paths = paths(@latest_diagnostics)

        (current_paths + previous_paths).map do |path|
          [path, @latest_diagnostics[path] || []]
        end.to_h
      end

      private

      def sanitize(diagnostics)
        diagnostics = diagnostics.map { |hash| find(hash) }.reject(&:nil?) if diagnostics[0]&.is_a?(Hash)
        diagnostics
      end

      def delete(relative_path, diagnostic)
        relative_path = Pathname.new(relative_path) if relative_path.is_a?(String)
        @mutex.synchronize do
          @latest_diagnostics[relative_path]&.delete(diagnostic)
          @latest_diagnostics.delete(relative_path) if @latest_diagnostics[relative_path]&.empty?
        end
      end

      def find(diagnostic_hash)
        diagnostics(diagnostic_hash.dig(:data, :relative_path))
          .find { |d| d == diagnostic_hash }
      end

      def document_changes(diagnostics)
        corrector = DocumentChangeCorrector.new
        diagnostics.each do |diagnostic|
          offense = diagnostic.offense
          offense.correct(corrector)
        end
        corrector.document_changes
      end

      def paths(diagnostics)
        (diagnostics || {}).keys.map { |path| Pathname.new(path) }.to_set
      end

      def single_file_diagnostics(relative_path)
        @latest_diagnostics[relative_path]&.select(&:single_file?) || []
      end

      def whole_theme_diagnostics(relative_path)
        @latest_diagnostics[relative_path]&.select(&:whole_theme?) || []
      end

      def previous_diagnostics(relative_path)
        @latest_diagnostics[relative_path]
      end
    end
  end
end
