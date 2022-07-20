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

    def relative_path(absolute_path)
      Pathname.new(absolute_path).relative_path_from(@root).to_s
    end

    def path(relative_path)
      @root.join(relative_path)
    end

    def read(relative_path)
      file(relative_path).read(mode: 'rb', encoding: 'UTF-8')
    rescue Errno::ENOENT
      nil
    end

    def write(relative_path, content)
      reset_memoizers unless file_exists?(relative_path)

      file(relative_path).dirname.mkpath unless file(relative_path).dirname.directory?
      file(relative_path).write(content, mode: 'w+b', encoding: 'UTF-8')
    end

    def remove(relative_path)
      file(relative_path).delete
      reset_memoizers
    end

    def mkdir(relative_path)
      return if file_exists?(relative_path)
      reset_memoizers
      file(relative_path).mkpath
    end

    def files
      @file_array ||= glob("**/*")
        .reject { |path| File.directory?(path) }
        .map { |path| path.relative_path_from(@root).to_s }
    end

    def directories
      @directories ||= glob('*')
        .select { |f| File.directory?(f) }
        .map { |f| f.relative_path_from(@root).to_s }
    end

    private

    def file_exists?(relative_path)
      !!@files[relative_path]
    end

    def reset_memoizers
      @file_array = nil
      @directories = nil
    end

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
