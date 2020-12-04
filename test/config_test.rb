# frozen_string_literal: true
require "test_helper"

class ConfigTest < Minitest::Test
  def test_load_file_uses_provided_config
    theme = make_theme(".theme-check.yml" => <<~END)
      TemplateLength:
        enabled: false
    END
    config = ThemeCheck::Config.from_path(theme.root).to_h
    assert_equal({ "TemplateLength" => { "enabled" => false } }, config)
  end

  def test_load_file_in_parent_dir
    theme = make_theme(
      ".theme-check.yml" => <<~END,
        TemplateLength:
          enabled: false
      END
      "dist/templates/index.liquid" => "",
    )
    config = ThemeCheck::Config.from_path(theme.root.join("dist")).to_h
    assert_equal({ "TemplateLength" => { "enabled" => false } }, config)
  end

  def test_missing_file
    theme = make_theme
    config = ThemeCheck::Config.from_path(theme.root).to_h
    assert_equal({}, config)
  end

  def test_from_path_uses_empty_config_when_config_file_is_missing
    ThemeCheck::Config.expects(:new).with('theme/')
    ThemeCheck::Config.from_path('theme/')
  end

  def test_enabled_checks_excludes_disabled_checks
    config = ThemeCheck::Config.new(".", "MissingTemplate" => { "enabled" => false })
    refute(check_enabled?(config, ThemeCheck::MissingTemplate))
  end

  def test_root
    config = ThemeCheck::Config.new(".", "root" => "dist", "MissingTemplate" => { "enabled" => false })
    assert_equal(Pathname.new("dist"), config.root)
    refute(check_enabled?(config, ThemeCheck::MissingTemplate))
  end

  def test_root_from_config_in_parent
    theme = make_theme(
      ".theme-check.yml" => <<~END,
        root: dist
      END
      "dist/templates/index.liquid" => "",
    )
    config = ThemeCheck::Config.from_path(theme.root)
    assert_equal(theme.root.join("dist"), config.root)
  end

  def test_picks_nearest_config
    theme = make_theme(
      ".theme-check.yml" => <<~END,
        TemplateLength:
          enabled: false
      END
      "src/.theme-check.yml" => <<~END,
        TemplateLength:
          enabled: true
      END
    )
    config = ThemeCheck::Config.from_path(theme.root.join("src"))
    assert_equal(theme.root.join("src"), config.root)
    assert(check_enabled?(config, ThemeCheck::TemplateLength))
  end

  def test_blank_root
    config = ThemeCheck::Config.new(".")
    assert_equal(Pathname.new("."), config.root)
  end

  def test_enabled_checks_returns_default_checks_for_empty_config
    YAML.expects(:load_file)
      .with { |path| path.end_with?('config/default.yml') }
      .returns("SyntaxError" => { "enabled" => true })
    config = ThemeCheck::Config.new(".")
    assert(check_enabled?(config, ThemeCheck::SyntaxError))
  end

  def test_config_overrides_default_config
    YAML.expects(:load_file)
      .with { |path| path.end_with?('config/default.yml') }
      .returns("SyntaxError" => { "enabled" => true })
    config = ThemeCheck::Config.new(".", "SyntaxError" => { "enabled" => false })
    refute(check_enabled?(config, ThemeCheck::SyntaxError))
  end

  private

  def check_enabled?(config, klass)
    config.enabled_checks.map(&:class).include?(klass)
  end
end
