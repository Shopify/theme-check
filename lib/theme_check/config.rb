# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'
    BUNDLED_CONFIGS_DIR = Pathname.new("#{__dir__}/../../config").realpath
    BOOLEAN = [true, false]

    attr_reader :root
    attr_accessor :auto_correct

    class << self
      attr_reader :last_loaded_config

      def from_path(path)
        if (filename = find(path))
          new(root: filename.dirname, configuration: load_config(filename))
        else
          # No configuration file
          new(root: path)
        end
      end

      def from_string(config)
        new(configuration: YAML.load(config), should_resolve_requires: false)
      end

      def from_hash(config)
        new(configuration: config, should_resolve_requires: false)
      end

      def find(root, needle = DOTFILE)
        Pathname.new(root).descend.reverse_each do |path|
          pathname = path.join(needle)
          return pathname if pathname.exist?
        end
        nil
      end

      def load_file(absolute_path)
        @last_loaded_config = absolute_path
        # An empty file returns false, so we || {}.
        YAML.load_file(absolute_path) || {}
      end

      def bundled_config_path(name)
        "#{BUNDLED_CONFIGS_DIR}/#{name.to_s.sub(/^:/, '')}.yml"
      end

      def bundled_config?(name)
        name.is_a?(Symbol) || (name.is_a?(String) && name[0] == ":")
      end

      def load_bundled_config(name)
        load_file(bundled_config_path(name))
      end

      def load_config(name, pwd = Pathname.pwd)
        return load_bundled_config(name) if bundled_config?(name)
        path = name.is_a?(Pathname) ? name : Pathname.new(name)
        path = pwd.join(path) if path.relative?
        return {} unless path.exist?
        config = load_file(path)
        extends = config["extends"] || :default
        merge_configurations!(load_config(extends, path.realpath.dirname), config)
      end

      def merge_configurations!(config, other)
        config.merge(other) do |_key, old_value, new_value|
          case old_value
          when Hash
            merge_configurations!(old_value, new_value)
          else
            new_value
          end
        end
      end

      def default
        load_config(":default")
      end
    end

    def initialize(root: nil, configuration: nil, should_resolve_requires: true)
      @configuration = if configuration
        validate_configuration(configuration)
      else
        self.class.default
      end

      extends = @configuration["extends"] || :default
      @configuration = self.class.merge_configurations!(self.class.load_config(extends), @configuration)

      @root = if root && @configuration.key?("root")
        Pathname.new(root).join(@configuration["root"])
      elsif root
        Pathname.new(root)
      end

      @auto_correct = false

      resolve_requires if @root && should_resolve_requires
    end

    def [](name)
      @configuration[name]
    end

    def to_h
      @configuration
    end

    def check_configurations
      @check_configurations ||= @configuration.select { |name, _| check_name?(name) }
    end

    def enabled_checks
      @enabled_checks ||= check_configurations.map do |check_name, options|
        next unless options["enabled"]

        check_class = ThemeCheck.const_get(check_name)

        next if check_class.categories.any? { |category| exclude_categories.include?(category) }
        next if include_categories.any? && !include_categories.all? { |category| check_class.categories.include?(category) }

        options_for_check = options.transform_keys(&:to_sym)
        options_for_check.delete(:enabled)
        severity = options_for_check.delete(:severity)
        check_ignored_patterns = options_for_check.delete(:ignore) || []
        check = if options_for_check.empty?
          check_class.new
        else
          check_class.new(**options_for_check)
        end
        check.severity = severity.to_sym if severity
        check.ignored_patterns = check_ignored_patterns + ignored_patterns
        check.options = options_for_check
        check
      end.compact
    end

    def ignored_patterns
      self["ignore"] || []
    end

    def include_categories
      self["include_categories"] || []
    end

    def include_categories=(categories)
      @configuration["include_categories"] = categories
    end

    def exclude_categories
      self["exclude_categories"] || []
    end

    def exclude_categories=(categories)
      @configuration["exclude_categories"] = categories
    end

    private

    def check_name?(name)
      name.to_s.start_with?(/[A-Z]/)
    end

    def validate_configuration(configuration, default_configuration = self.class.default, parent_keys = [])
      valid_configuration = {}

      configuration.each do |key, value|
        # No validation possible unless we have a default to compare to
        unless default_configuration
          valid_configuration[key] = value
          next
        end

        default = default_configuration[key]
        keys = parent_keys + [key]
        name = keys.join(".")

        if check_name?(key)
          if value.is_a?(Hash)
            valid_configuration[key] = validate_configuration(value, default, keys)
          else
            warn("bad configuration type for #{name}: expected a Hash, got #{value.inspect}")
          end
        elsif key == "extends"
          if value.is_a?(Symbol) || value.is_a?(String)
            valid_configuration[key] = value
          else
            warn("bad configuration type for extends: expected a Symbol or a String, got #{value.inspect}")
          end
        elsif key == "severity"
          valid_configuration[key] = value
        elsif default.nil?
          warn("unknown configuration: #{name}")
        elsif BOOLEAN.include?(default) && !BOOLEAN.include?(value)
          warn("bad configuration type for #{name}: expected true or false, got #{value.inspect}")
        elsif !BOOLEAN.include?(default) && default.class != value.class
          warn("bad configuration type for #{name}: expected a #{default.class}, got #{value.inspect}")
        else
          valid_configuration[key] = value
        end
      end

      valid_configuration
    end

    def resolve_requires
      self["require"]&.each do |path|
        file_to_require = @root.join(path).realpath
        require(file_to_require.to_s)
      end
    end
  end
end
