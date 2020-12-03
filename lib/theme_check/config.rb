# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'

    class << self
      def load_file(path)
        if (filename = find(path))
          new(YAML.load_file(filename))
        else
          # Configuration file is optional
          new({})
        end
      end

      def find(root)
        path = Pathname(root)
        until path.expand_path.root?
          filename = path.join(DOTFILE)
          return filename if filename.file?
          path = path.parent
        end
      end
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def to_h
      @configuration
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
