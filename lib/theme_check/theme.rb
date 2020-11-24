# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    attr_reader :root, :file_system

    def initialize(root)
      @root = Pathname.new(root)
      @file_system = Liquid::LocalFileSystem.new(@root, "%.liquid")
    end

    def all_files_paths
      @root.glob("**/*.liquid")
    end

    def template_paths
      @root.glob("templates/**/*.liquid")
    end

    def section_paths
      @root.glob("sections/**/*.liquid")
    end

    def snippets
      @root.glob("snippets/**/*.liquid").map { |p| p.relative_path_from(@root).to_s }
    end

    def template_path(name)
      @root.join("#{name}.liquid")
    end
  end
end
