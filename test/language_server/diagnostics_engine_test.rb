# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class DiagnosticsEngineTest < Minitest::Test
      include URIHelper

      def setup
        @messenger = MockMessenger.new
        @bridge = Bridge.new(@messenger)
        @storage = make_file_system_storage(
          "layout/theme.liquid" => "{% render 'a' %}{% render 'b' %}",
          "snippets/a.liquid" => "{% if unclosed %}",
          "snippets/b.liquid" => "{% if unclosed %}",
          "snippets/c.liquid" => "",
          ".theme-check.yml" => <<~YML,
            extends: :nothing
            SyntaxError:
              enabled: true
            UnusedSnippet:
              enabled: true
          YML
        )
        @engine = DiagnosticsEngine.new(@storage, @bridge)
      end

      def test_analyze_and_send_offenses_full_on_first_run_partial_second_run
        # On the first run, analyze the entire theme
        analyze_and_send_offenses("layout/theme.liquid")

        # Expect diagnostics for all files
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/a.liquid", [:syntax]))
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/b.liquid", [:syntax]))
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # Secretly correct all the files
        @storage.write("snippets/a.liquid", "{% if unclosed %}{% endif %}")
        @storage.write("snippets/b.liquid", "{% if unclosed %}{% endif %}")

        # Rerun analyze_and_send_offenses on a file
        @messenger.sent_messages.clear
        analyze_and_send_offenses("snippets/a.liquid")

        # Expect empty diagnostics for the file that was fixed
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/b.liquid"))

        # Run it on the other file that was fixed
        analyze_and_send_offenses("snippets/b.liquid")

        # Expect empty diagnostics for the other file that was fixed
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))
      end

      def test_analyze_and_send_offenses_with_only_single_file
        # Only expect single file diagnostics for the file checked
        analyze_and_send_offenses("snippets/a.liquid", only_single_file: true)
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/a.liquid", [:syntax]))
        refute_includes(@messenger.sent_messages, diagnostics_notification("snippets/b.liquid", [:syntax]))
        refute_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # whole theme checks are ignored in this mode
        analyze_and_send_offenses("snippets/c.liquid", only_single_file: true)
        refute_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # Correct the file
        @storage.write("snippets/a.liquid", "{% if unclosed %}{% endif %}")
        @storage.write("snippets/b.liquid", "{% if unclosed %}{% endif %}")

        # Rerun analyze_and_send_offenses on a file
        @messenger.sent_messages.clear
        analyze_and_send_offenses("snippets/a.liquid")

        # Expect empty diagnostics for the file that was fixed
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/b.liquid"))
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/c.liquid"))

        # Run it on the other file that was fixed
        analyze_and_send_offenses("snippets/b.liquid")

        # Do not expect empty diagnostics for that file, diagnostics were never sent
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/b.liquid"))
      end

      # For when you want fast checks on change but slow changes on save
      def test_analyze_and_send_offenses_mixed_mode
        # Run a full theme check on first run
        analyze_and_send_offenses("snippets/a.liquid")
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/a.liquid", [:syntax]))
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/b.liquid", [:syntax]))
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # Fix an error by typing code, but only run single file checks
        @messenger.sent_messages.clear
        @storage.write("snippets/a.liquid", "{% if unclosed %}{% endif %}")
        analyze_and_send_offenses("snippets/a.liquid", only_single_file: true)

        # Get updated diagnostics for that file, but not the untouched ones
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/c.liquid"))
        refute_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # Fix the UnusedSnippet error by typing
        @messenger.sent_messages.clear
        @storage.write("layout/theme.liquid", "{% render 'a' %}{% render 'b' %}{% render 'c' %}")
        analyze_and_send_offenses("layout/theme.liquid", only_single_file: true)

        # Don't expect empty or resent diagnostics for the fixed file
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/c.liquid"))
        refute_includes(@messenger.sent_messages, diagnostics_notification("snippets/c.liquid", [:unused]))

        # Hit "save", run whole theme checks. Remove the fixed offense.
        analyze_and_send_offenses("layout/theme.liquid")
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/c.liquid"))
      end

      # If you run analyze_and_send_offenses while one is running, the test should be skipped.
      def test_analyze_and_send_offenses_is_throttled
        skip "Flaky test"
        # Setup test in single file mode
        analyze_and_send_offenses("snippets/a.liquid")
        @messenger.sent_messages.clear

        threads = []
        10.times do
          threads << Thread.new do
            analyze_and_send_offenses("snippets/a.liquid")
          end
        end
        threads.each { |t| t.join if t.alive? }
        assert(@messenger.sent_messages.size < threads.size)
      end

      def analyze_and_send_offenses(path, only_single_file: false)
        @engine.analyze_and_send_offenses(
          @storage.path(path),
          PlatformosCheck::Config.from_path(@storage.root),
          only_single_file: only_single_file
        )
      end

      def diagnostics_notification(path, error_types)
        diagnostics = []
        diagnostics << unused_snippet(path) if error_types.include?(:unused)
        diagnostics << syntax_error(path) if error_types.include?(:syntax)
        {
          jsonrpc: "2.0",
          method: "textDocument/publishDiagnostics",
          params: {
            uri: file_uri(@storage.path(path)),
            diagnostics: diagnostics,
          },
        }
      end

      def empty_diagnostics_notification(path)
        diagnostics_notification(path, [])
      end

      def unused_snippet(path)
        {
          code: "UnusedSnippet",
          message: "This snippet is not used",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 0 },
          },
          severity: 2,
          source: "theme-check",
          codeDescription: {
            href: "https://github.com/Shopify/theme-check/blob/main/docs/checks/unused_snippet.md",
          },
          data: {
            uri: file_uri(@storage.path(path)),
            absolute_path: @storage.path(path).to_s,
            relative_path: path.to_s,
            version: nil,
          },
        }
      end

      def syntax_error(path)
        {
          code: "SyntaxError",
          message: "'if' tag was never closed",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 16 },
          },
          severity: 1,
          source: "theme-check",
          codeDescription: {
            href: "https://github.com/Shopify/theme-check/blob/main/docs/checks/syntax_error.md",
          },
          data: {
            uri: file_uri(@storage.path(path)),
            absolute_path: @storage.path(path).to_s,
            relative_path: path.to_s,
            version: nil,
          },
        }
      end
    end
  end
end
