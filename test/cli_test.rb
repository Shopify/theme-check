# frozen_string_literal: true
require "test_helper"
require "active_support/testing/stream"

class CliTest < Minitest::Test
  include ActiveSupport::Testing::Stream

  def test_help
    cli = ThemeCheck::Cli.new
    assert_raises(ThemeCheck::Cli::Abort, /^usage: /) do
      cli.run(%w(--help))
    end
  end

  def test_check
    cli = ThemeCheck::Cli.new
    out = capture(:stdout) do
      assert_raises(ThemeCheck::Cli::Abort) do
        cli.run([__dir__ + "/theme"])
      end
    end
    assert_includes(out, "files inspected")
  end

  def test_check_with_category
    cli = ThemeCheck::Cli.new
    out = capture(:stdout) do
      assert_raises(ThemeCheck::Cli::Abort) do
        cli.run([__dir__ + "/theme", "-c", "translation"])
      end
    end
    refute_includes(out, "liquid")
  end

  def test_check_with_exclude_category
    cli = ThemeCheck::Cli.new
    out = capture(:stdout) do
      assert_raises(ThemeCheck::Cli::Abort) do
        cli.run([__dir__ + "/theme", "-x", "liquid"])
      end
    end
    refute_includes(out, "liquid")
  end

  def test_check_no_templates
    cli = ThemeCheck::Cli.new
    assert_raises(ThemeCheck::Cli::Abort, /^No templates found./) do
      silence_stream(STDOUT) do
        cli.run([__dir__])
      end
    end
  end

  def test_list
    cli = ThemeCheck::Cli.new
    out = capture(:stdout) do
      cli.run(%w(--list))
    end
    assert_includes(out, "LiquidTag:")
  end

  def test_auto_correct
    cli = ThemeCheck::Cli.new
    out = capture(:stdout) do
      assert_raises(ThemeCheck::Cli::Abort) do
        cli.run([__dir__ + "/theme", "-a"])
      end
    end
    assert_includes(out, "corrected")
  end
end
