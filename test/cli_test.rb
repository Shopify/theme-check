# frozen_string_literal: true
require "test_helper"

class CliTest < Minitest::Test
  def test_help
    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!(%w(--help))
    end

    assert_includes(out, "Usage: theme-check")
  end

  def test_check
    out, _err = capture_io do
      assert_raises(PlatformosCheck::Cli::Abort) do
        PlatformosCheck::Cli.parse_and_run!([__dir__ + "/theme"])
      end
    end
    assert_includes(out, "files inspected")
  end

  def test_check_format_json
    storage = make_file_system_storage(
      "layout/theme.liquid" => <<~LIQUID,
        {% assign x = 1 %}
        {% assign y = 2 %}
      LIQUID
      "config/placeholder" => '',
      "assets/placeholder" => '',
      "locales/placeholder" => '',
      "snippets/example.liquid" => '',
      "templates/example.liquid" => <<~LIQUID,
        {% assign z = 1 %}
      LIQUID
      ".theme-check.yml" => <<~YAML,
        extends: :nothing
        UnusedAssign:
          enabled: true
        RequiredDirectories:
          enabled: true
          severity: suggestion
      YAML
    )

    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([storage.root.to_s, '--output', 'json'])
    end

    assert_equal(
      JSON.dump([
        {
          "path" => nil,
          "offenses" => [
            {
              "check" => "RequiredDirectories",
              "severity" => 1,
              "start_row" => 0,
              "start_column" => 0,
              "end_row" => 0,
              "end_column" => 0,
              "message" => "Theme is missing 'sections' directory",
            },
          ],
          "errorCount" => 0,
          "suggestionCount" => 1,
          "styleCount" => 0,
        },
        {
          "path" => "layout/theme.liquid",
          "offenses" => [
            {
              "check" => "UnusedAssign",
              "severity" => 1,
              "start_row" => 0,
              "start_column" => 3,
              "end_row" => 0,
              "end_column" => 16,
              "message" => "`x` is never used",
            },
            {
              "check" => "UnusedAssign",
              "severity" => 1,
              "start_row" => 1,
              "start_column" => 3,
              "end_row" => 1,
              "end_column" => 16,
              "message" => "`y` is never used",
            },
          ],
          "errorCount" => 0,
          "suggestionCount" => 2,
          "styleCount" => 0,
        },
        {
          "path" => "templates/example.liquid",
          "offenses" => [
            {
              "check" => "UnusedAssign",
              "severity" => 1,
              "start_row" => 0,
              "start_column" => 3,
              "end_row" => 0,
              "end_column" => 16,
              "message" => "`z` is never used",
            },
          ],
          "errorCount" => 0,
          "suggestionCount" => 1,
          "styleCount" => 0,
        },
      ]),
      out.chomp
    )
  end

  def test_print
    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([__dir__ + "/theme", '--print'])
    end

    assert_includes(out, <<~EXPECTED)
      SyntaxError:
        enabled: true
    EXPECTED
  end

  def test_config_flag
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~YAML,
        SyntaxError:
          enabled: false
      YAML
    )

    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([__dir__ + "/theme", "-C", storage.path(".theme-check.yml").to_s, '--print'])
    end

    assert_includes(out, <<~EXPECTED)
      SyntaxError:
        enabled: false
    EXPECTED
  end

  def test_check_with_category
    out, _err = capture_io do
      assert_raises(PlatformosCheck::Cli::Abort) do
        PlatformosCheck::Cli.parse_and_run!([__dir__ + "/theme", "-c", "translation", "--fail-level", "style"])
      end
    end
    refute_includes(out, "liquid")
  end

  def test_check_with_exclude_category
    out, _err = capture_io do
      assert_raises(PlatformosCheck::Cli::Abort) do
        PlatformosCheck::Cli.parse_and_run!([__dir__ + "/theme", "-x", "liquid", "--fail-level", "style"])
      end
    end
    refute_includes(out, "liquid")
  end

  def test_check_no_templates
    assert_raises(PlatformosCheck::Cli::Abort, /^No templates found./) do
      capture_io do
        PlatformosCheck::Cli.parse_and_run!([__dir__])
      end
    end
  end

  def test_list
    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!(%w(--list))
    end
    assert_includes(out, "LiquidTag:")
  end

  def test_update_docs
    PlatformosCheck::ShopifyLiquid::SourceManager.expects(:download)

    storage = make_file_system_storage(
      'layout/theme.liquid' => '',
      '.theme-check.yml' => <<~YAML,
        extends: :nothing
        RequiredDirectories:
          enabled: false
      YAML
    )

    _out, err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([storage.root, '--update-docs'])
    end

    assert_includes(err, 'Updating documentation...')
  end

  def test_auto_correct
    storage = make_file_system_storage(
      "templats/theme.liquid" => <<~LIQUID,
        {{ content_for_header }}
      LIQUID
    )
    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([storage.root.to_s, "-a"])
    end
    assert_includes(out, "corrected")
  end

  def test_fail_level_and_exit_codes
    assert_exit_code(2, "error",
      "templates/theme.liquid" => <<~YAML,
        {% unknown %}
      YAML
      "crash_test_check.rb" => <<~RUBY,
        # frozen_string_literal: true
        module PlatformosCheck
          class MockCheck < LiquidCheck
            severity :error
            category :liquid
            doc docs_url(__FILE__)

            def on_end
              raise StandardError, "This is a crash test."
            end
          end
        end
      RUBY
      ".theme-check.yml" => <<~YAML,
        extends: :nothing
        require:
          - ./crash_test_check.rb
        MockCheck:
          enabled: true
      YAML
    )

    # Teardown code so that Checks.all doesn't have MockCheck in it
    PlatformosCheck::Check.all.delete(PlatformosCheck::MockCheck)

    assert_exit_code(1, "error",
      "templates/theme.liquid" => <<~YAML,
        {% unknown %}
      YAML
      ".theme-check.yml" => <<~YAML,
        extends: :nothing
        SyntaxError:
          enabled: true
      YAML
    )

    assert_exit_code(0, "error",
      "templates/theme.liquid" => <<~YAML,
        {% unknown %}
      YAML
      ".theme-check.yml" => <<~YAML,
        extends: :nothing
        SyntaxError:
          enabled: true
          severity: suggestion
      YAML
    )
  end

  def test_init
    storage = make_file_system_storage
    out, _err = capture_io do
      PlatformosCheck::Cli.parse_and_run!([storage.root, "--init"])
    end
    assert_includes(out, "Writing new .theme-check.yml")
  end

  def test_init_abort_with_existing_config_file
    storage = make_file_system_storage(
      ".theme-check.yml" => <<~END,
        root: .
      END
    )
    assert_raises(PlatformosCheck::Cli::Abort, /^.theme-check.yml already exists/) do
      capture_io do
        PlatformosCheck::Cli.parse_and_run!([storage.root, "--init"])
      end
    end
  end

  private

  def capture_io(&block)
    err = nil
    out = capture(:stdout) do
      err = capture(:stderr) do
        block.call
      end
    end
    [out, err]
  end

  def assert_exit_code(exit_code, severity, files = {})
    storage = make_file_system_storage(files)

    err = assert_raises(SystemExit) do
      capture_io do
        PlatformosCheck::Cli.parse_and_run([storage.root, "--fail-level", severity, "-C", storage.path(".theme-check.yml").to_s])
      end
    end

    assert_equal(exit_code, err.status)
  end
end
