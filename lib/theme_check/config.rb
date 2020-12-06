# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'
    DEFAULT_CONFIG = "#{__dir__}/../../config/default.yml"

    attr_reader :root

    class << self
      def from_path(path)
        if (filename = find(path))
          new(filename.dirname, load_file(filename))
        else
          # No configuration file
          new(path)
        end
      end

      def find(root, needle = DOTFILE)
        Pathname.new(root).descend.reverse_each do |path|
          pathname = path.join(needle)
          return pathname if pathname.exist?
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
      resolve_requires
    end

    def to_h
      @configuration
    end

    def enabled_checks
      checks = []

      default_configuration.merge(@checks).each do |check_name, properties|
        if @checks[check_name] && !default_configuration[check_name].nil?
          valid_properties = valid_check_configuration(check_name)
          properties = properties.merge(valid_properties)
        end

        next if properties.delete('enabled') == false

        check = ThemeCheck.const_get(check_name).new(**properties.transform_keys(&:to_sym))
        checks << check
      end

      checks
    end

    private

    def default_configuration
      @default_configuration ||= Config.load_file(DEFAULT_CONFIG)
    end

    def resolve_requires
      if @checks.key?("require")
        @checks.delete("require").tap do |paths|
          paths.each do |path|
            if path.start_with?('.')
              require(File.join(@root, path))
            end
          end
        end
      end
    end

    def valid_check_configuration(check_name)
      default_properties = default_configuration[check_name]

      valid = {}

      @checks[check_name].each do |property, value|
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
