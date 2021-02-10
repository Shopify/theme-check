# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class FileSystemStorage < Storage
    attr_reader :root

    def initialize(root, ignored_patterns: [])
      @root = Pathname.new(root)
      @ignored_patterns = ignored_patterns
      @files = {}
    end

    def path(relative_path)
      @root.join(relative_path)
    end

    def read(relative_path)
      file(relative_path).read
    end

    def write(relative_path, content)
      file(relative_path).write(content)
    end

    def files
      @file_array ||= glob("**/*")
        .map { |path| path.relative_path_from(@root).to_s }
    end

    def directories
      @directories ||= glob('*')
        .select { |f| File.directory?(f) }
        .map { |f| f.relative_path_from(@root).to_s }
    end

    private

    def glob(pattern)
      @root.glob(pattern).reject do |path|
        relative_path = path.relative_path_from(@root)
        @ignored_patterns.any? { |ignored| relative_path.fnmatch?(ignored) }
      end
    end

    def file(name)
      return @files[name] if @files[name]
      @files[name] = root.join(name)
    end
  end
end
