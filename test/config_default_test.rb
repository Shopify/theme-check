# frozen_string_literal: true
require "test_helper"
require "yaml"

module ThemeCheck
  class ConfigDefaultTest < Minitest::Test
    def setup
      @default_config = YAML.load(default_config_path.read)
    end

    def test_all_checks_are_in_config_default_yml
      Check.all.each do |check_class|
        check = check_class.new
        next if check.code_name == "MockCheck"
        refute_nil(@default_config.dig(check.code_name), "#{check.code_name} and its default configuration should be included in config/default.yml")
        refute_nil(@default_config.dig(check.code_name, 'enabled'), "#{check.code_name} should have a default 'enabled:' value in config/default.yml")
      end
    end

    private

    def default_config_path
      Pathname.new(__dir__) + '../config/default.yml'
    end
  end
end
