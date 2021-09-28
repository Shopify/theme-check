# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class DiagnosticsTrackerTest < Minitest::Test
      Offense = Struct.new(
        :code_name,
        :theme_file,
        :whole_theme?,
      ) do
        def single_file?
          !whole_theme?
        end

        def inspect
          "#<#{code_name} theme_file=\"#{theme_file.path}\" #{whole_theme? ? 'whole_theme' : 'single_file'}>"
        end
      end
      LiquidFile = Struct.new(:path)

      class WholeThemeOffense < Offense
        def initialize(code_name, path)
          super(code_name, LiquidFile.new(Pathname.new(path)), true)
        end
      end

      class SingleFileOffense < Offense
        def initialize(code_name, path)
          super(code_name, LiquidFile.new(Pathname.new(path)), false)
        end
      end

      def setup
        @tracker = DiagnosticsTracker.new
      end

      def test_reports_all_on_first_run
        assert_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
          ],
          analyzed_files: [
            "template/index.liquid",
            "template/collection.liquid",
          ],
          diagnostics: {
            "template/index.liquid" => [
              WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
              SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
            ],
            "template/collection.liquid" => [
              SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
            ],
          },
        )
      end

      def test_reports_empty_when_offenses_are_fixed_in_subsequent_calls
        build_diagnostics(
          offenses: [
            SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
            SingleFileOffense.new("UnknownFilter", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
          ],
        )
        assert_diagnostics(
          offenses: [
            SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
          ],
          analyzed_files: [
            "template/index.liquid",
            "template/collection.liquid",
          ],
          diagnostics: {
            "template/index.liquid" => [],
            "template/collection.liquid" => [
              SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
            ],
          },
        )
        assert_diagnostics(
          offenses: [],
          analyzed_files: [
            "template/collection.liquid",
          ],
          diagnostics: {
            "template/collection.liquid" => [],
          },
        )
      end

      def test_include_single_file_offenses_of_previous_runs
        build_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
          ],
        )
        assert_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
          ],
          analyzed_files: [
            "template/collection.liquid",
          ],
          diagnostics: {
            "template/index.liquid" => [
              WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
              SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
            ],
            "template/collection.liquid" => [
              SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
            ],
          },
        )
      end

      def test_clears_whole_theme_offenses_from_previous_runs
        build_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
          ],
        )
        assert_diagnostics(
          offenses: [
            SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
          ],
          analyzed_files: [
            "template/collection.liquid",
          ],
          diagnostics: {
            "template/index.liquid" => [],
            "template/collection.liquid" => [
              SingleFileOffense.new("UnusedAssign", "template/collection.liquid"),
            ],
          },
        )
      end

      def test_clears_single_theme_offenses_when_missing
        build_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
          ],
        )
        assert_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
          ],
          analyzed_files: [
            "template/index.liquid",
          ],
          diagnostics: {
            "template/index.liquid" => [
              WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            ],
          },
        )
      end

      def test_single_file_offenses_returns_offenses_for_an_absolute_path
        build_diagnostics(
          offenses: [
            WholeThemeOffense.new("MissingTemplate", "template/index.liquid"),
            SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
            SingleFileOffense.new("SyntaxError", "template/index.liquid"),
          ],
        )
        expected = [
          SingleFileOffense.new("UnusedAssign", "template/index.liquid"),
          SingleFileOffense.new("SyntaxError", "template/index.liquid"),
        ]
        assert_equal(expected, @tracker.single_file_offenses(Pathname.new("template/index.liquid")))
        assert_equal(expected, @tracker.single_file_offenses("template/index.liquid"))
      end

      private

      def build_diagnostics(offenses:, analyzed_files: nil)
        actual_diagnostics = {}
        @tracker.build_diagnostics(offenses, analyzed_files: analyzed_files) do |path, diagnostic_offenses|
          actual_diagnostics[path] = diagnostic_offenses
        end
        actual_diagnostics
      end

      def assert_diagnostics(offenses:, analyzed_files:, diagnostics:)
        actual_diagnostics = build_diagnostics(offenses: offenses, analyzed_files: analyzed_files)
        assert_equal(diagnostics, actual_diagnostics.transform_keys(&:to_s))
      end
    end
  end
end
