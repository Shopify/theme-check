# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class FileSystemTheme < Theme
    DEFAULT_LOCALE_REGEXP = %r{^locales/(.*)\.default$}
    attr_reader :root

    def initialize(root, ignored_patterns: [])
      @root = Pathname.new(root)
      @ignored_patterns = ignored_patterns
    end

    def liquid
      @liquid ||= glob("**/*.liquid").map { |path| FileSystemTemplate.new(path, @root) }
    end

    def json
      @json ||= glob("**/*.json").map { |path| FileSystemJsonFile.new(path, @root) }
    end

    def directories
      @directories ||= glob('*').select { |f| File.directory?(f) }.map { |f| f.relative_path_from(@root) }
    end

    private

    def glob(pattern)
      @root.glob(pattern).reject do |path|
        relative_path = path.relative_path_from(@root)
        @ignored_patterns.any? { |ignored| relative_path.fnmatch?(ignored) }
      end
    end
  end
end
