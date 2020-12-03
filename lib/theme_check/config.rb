# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'

    class << self
      def load_file(path)
        new(YAML.load_file(File.join(path, DOTFILE)))
      rescue Errno::ENOENT
        # Configuration file is optional
        new({})
      end
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def enabled_checks
      return [] unless @configuration

      checks = []

      Check.all.each do |check|
        class_name = check.name.split('::').last
        if !@configuration.key?(class_name) || @configuration[class_name]["enabled"] == true
          checks << check.new
        end
      end

      checks
    end
  end
end
