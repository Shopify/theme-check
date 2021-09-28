# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class DiagnosticsEngineTest < Minitest::Test
      include URIHelper

      def setup
        @messenger = MockMessenger.new
        @bridge = Bridge.new(@messenger)
        @storage = make_file_system_storage(
          "layout/theme.liquid" => "{% if unclosed %}",
          "snippets/a.liquid" => "{% if unclosed %}",
          ".theme-check.yml" => <<~YML,
            extends: :nothing
            SyntaxError:
              enabled: true
          YML
        )
        @engine = DiagnosticsEngine.new(@storage, @bridge)
      end

      def test_analyze_and_send_offenses_full_on_first_run_partial_second_run
        # On the first run, analyze the entire theme
        analyze_and_send_offenses("layout/theme.liquid")

        # Expect diagnostics for all files
        assert_includes(@messenger.sent_messages, diagnostics_notification("layout/theme.liquid"))
        assert_includes(@messenger.sent_messages, diagnostics_notification("snippets/a.liquid"))

        # Secretly correct all the files
        @storage.write("layout/theme.liquid", "{% if unclosed %}{% endif %}")
        @storage.write("snippets/a.liquid", "{% if unclosed %}{% endif %}")

        # Rerun analyze_and_send_offenses on a file
        @messenger.sent_messages.clear
        analyze_and_send_offenses("layout/theme.liquid")

        # Expect empty diagnostics for the file that was fixed
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("layout/theme.liquid"))
        refute_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))

        # Run it on the other file that was fixed
        analyze_and_send_offenses("snippets/a.liquid")

        # Expect empty diagnostics for the other file that was fixed
        assert_includes(@messenger.sent_messages, empty_diagnostics_notification("snippets/a.liquid"))
      end

      # If you run analyze_and_send_offenses while one is running, the test should be skipped.
      def test_analyze_and_send_offenses_is_debounced
        # Setup test in single file mode
        analyze_and_send_offenses("layout/theme.liquid")
        @messenger.sent_messages.clear

        threads = []
        10.times do
          threads << Thread.new do
            analyze_and_send_offenses("layout/theme.liquid")
          end
        end
        threads.each { |t| t.join if t.alive? }
        assert(@messenger.sent_messages.size < threads.size)
      end

      def analyze_and_send_offenses(path)
        @engine.analyze_and_send_offenses(@storage.path(path), ThemeCheck::Config.from_path(@storage.root))
      end

      def diagnostics_notification(path)
        {
          jsonrpc: "2.0",
          method: "textDocument/publishDiagnostics",
          params: {
            uri: file_uri(@storage.path(path)),
            diagnostics: expected_diagnostics(path),
          },
        }
      end

      def empty_diagnostics_notification(path)
        {
          jsonrpc: "2.0",
          method: "textDocument/publishDiagnostics",
          params: {
            uri: file_uri(@storage.path(path)),
            diagnostics: [],
          },
        }
      end

      def expected_diagnostics(path)
        [
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
              path: @storage.path(path).to_s,
              version: nil,
            },
          },
        ]
      end
    end
  end
end
