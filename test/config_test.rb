# frozen_string_literal: true
require "test_helper"

class ConfigTest < Minitest::Test
  def test_load_file_uses_provided_config
    theme = make_theme(".theme-check.yml" => <<~END)
      TemplateLength:
        enabled: false
    END
    config = ThemeCheck::Config.load_file(theme.root).to_h
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
    config = ThemeCheck::Config.load_file(theme.root.join("dist")).to_h
    assert_equal({ "TemplateLength" => { "enabled" => false } }, config)
  end

  def test_missing_file
    theme = make_theme
    config = ThemeCheck::Config.load_file(theme.root).to_h
    assert_equal({}, config)
  end

  def test_load_file_uses_empty_config_when_config_file_is_missing
    ThemeCheck::Config.expects(:new).with({})
    ThemeCheck::Config.load_file('theme/')
  end

  def test_enabled_checks_excludes_disabled_checks
    config = ThemeCheck::Config.new("MissingTemplate" => { "enabled" => false })
    refute(check_enabled?(config, ThemeCheck::MissingTemplate))
  end

  def test_enabled_checks_excludes_checks_without_enabled_key
    config = ThemeCheck::Config.new("MissingTemplate" => {})
    refute(check_enabled?(config, ThemeCheck::MissingTemplate))
  end

  def test_enabled_checks_has_all_check
    config = ThemeCheck::Config.new({})
    assert_equal(
      ThemeCheck::Check.all.to_set,
      config.enabled_checks.map(&:class).to_set
    )
  end

  private

  def check_enabled?(config, klass)
    config.enabled_checks.map(&:class).include?(klass)
  end
end
