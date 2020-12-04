# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'
    DEFAULT_CONFIG = 'config/default.yml'

    attr_reader :root

    class << self
      def from_path(path)
        if (filename = find(path))
          new(filename.dirname, load_file(filename))
        else
          # Configuration file is optional
          new(path)
        end
      end

      def find(root)
        Pathname.new(root).descend.reverse_each do |path|
          filename = path.join(DOTFILE)
          return filename if filename.file?
        end
        nil
      end

      def load_file(absolute_path)
        YAML.load_file(absolute_path)
      end
    end

    def initialize(root, configuration = {})
      @configuration = configuration
      @checks = configuration.dup
      @root = Pathname.new(root)
      if @checks.key?("root")
        @root = @root.join(@checks.delete("root"))
      end
    end

    def to_h
      @configuration
    end

    def enabled_checks
      checks = []

      default_configuration.each do |check_name, properties|
        if @checks&.key?(check_name)
          valid_properties = valid_check_configuration(check_name)
          properties = properties.merge(valid_properties)
        end

        next if properties['enabled'] == false

        properties.delete('enabled')
        check = ThemeCheck.const_get(check_name).new(**properties.transform_keys(&:to_sym))
        checks << check
      end

      checks
    end

    private

    def default_configuration
      @default_configuration ||= Config.load_file(DEFAULT_CONFIG)
    end

    def valid_check_configuration(check_name)
      default_properties = default_configuration[check_name]
      valid = {}

      @configuration[check_name].each do |property, value|
        if !default_properties.key?(property)
          warn("#{check_name} does not support #{property} parameter.")
        else
          valid[property] = value
        end
      end

      valid
    end
  end
end
