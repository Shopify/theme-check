# frozen_string_literal: true
require "logger"

module ThemeCheck
  module LanguageServer
    class DiagnosticsTracker
      # The LSP expects an empty array of diagnostics when we want to
      # clear previous ones.
      CLEAR = []

      # This class exists to facilitate LanguageServer diagnostics tracking.
      #
      # Motivations:
      #   1. The first time we lint, we want all the errors from all the files.
      #   2. If we fix all the errors in a file, we have to send an empty array for that file.
      #   3. If we do a partial check, we should consider the whole theme diagnostics as valid, and return cached results
      #   4. When CodeAction and Commands interact with each other, we can locate the offense from the diagnostic.
      def initialize
        @latest_diagnostics = {} # { [Pathname(absolute_path)] => Diagnostic[] }
        @mutex = Mutex.new
        @first_run = true
      end

      def first_run?
        @first_run
      end

      def diagnostics(absolute_path)
        absolute_path = Pathname.new(absolute_path) if absolute_path.is_a?(String)
        @mutex.synchronize { @latest_diagnostics[absolute_path] || [] }
      end

      def build_diagnostics(offenses, analyzed_files: nil)
        @mutex.synchronize do
          full_check = analyzed_files.nil?
          analyzed_paths = analyzed_files.map { |path| Pathname.new(path) } unless full_check

          # When analyzed_files is nil, contains all offenses.
          # When analyzed_files is !nil, contains all whole theme offenses and single file offenses of the analyzed_files.
          current_diagnostics = offenses
            .select(&:theme_file)
            .group_by(&:theme_file)
            .transform_keys { |theme_file| Pathname.new(theme_file.path) }
            .transform_values do |theme_file_offenses|
              theme_file_offenses.map { |o| Diagnostic.new(o) }
            end

          previous_paths = paths(@latest_diagnostics)
          current_paths = paths(current_diagnostics)

          diagnostics_update = (current_paths + previous_paths).map do |path|
            # When doing a full_check, we either send the current
            # diagnostics or an empty array to clear the diagnostics
            # for that file.
            if full_check
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

          @latest_diagnostics = diagnostics_update.reject { |_, v| v.empty? }
          @first_run = false
          diagnostics_update
        end
      end

      private

      def paths(diagnostics)
        (diagnostics || {}).keys.map { |path| Pathname.new(path) }.to_set
      end

      def single_file_diagnostics(absolute_path)
        @latest_diagnostics[absolute_path]&.select(&:single_file?) || []
      end
    end
  end
end
