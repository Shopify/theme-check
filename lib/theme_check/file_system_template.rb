# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class FileSystemTemplate < Template
    attr_reader :path

    def initialize(path, root)
      @path = Pathname(path)
      @root = Pathname(root)
      @updated = false
    end

    def relative_path
      @path.relative_path_from(@root)
    end

    def source
      @source ||= @path.read
    end

    def write
      if source != updated_source
        @path.write(updated_source)
      end
    end
  end
end
