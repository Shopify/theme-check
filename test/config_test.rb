# frozen_string_literal: true
require "test_helper"

class ConfigTest < Minitest::Test
  def test_load_file_uses_provided_config
    YAML.expects(:load_file).with('theme/.theme-check.yml').returns(config_hash)
    ThemeCheck::Config.expects(:new).with(config_hash)
    ThemeCheck::Config.load_file('theme/')
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

  def config_hash
    @config_hash ||= YAML.parse(<<~YAML)
      MissingTemplate:
        enabled: true
    YAML
  end

  def check_enabled?(config, klass)
    config.enabled_checks.map(&:class).include?(klass)
  end
end
