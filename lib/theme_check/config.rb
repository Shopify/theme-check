# frozen_string_literal: true

module ThemeCheck
  class Config
    DOTFILE = '.theme-check.yml'

    attr_reader :root

    class << self
      def load_file(path)
        if (filename = find(path))
          new(filename.dirname, YAML.load_file(filename))
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

      Check.all.each do |check|
        class_name = check.name.split('::').last
        if !@checks.key?(class_name) || @checks[class_name]["enabled"] == true
          checks << check.new
        end
      end

      checks
    end
  end
end
