# frozen_string_literal: true
require "json"
require "pathname"

module ThemeCheck
  class FileSystemJsonFile < JsonFile
    attr_reader :path

    def initialize(path, root)
      @path = Pathname(path)
      @root = Pathname(root)
      @loaded = false
      @content = nil
      @parser_error = nil
    end

    def relative_path
      @path.relative_path_from(@root)
    end

    def content
      load!
      @content
    end

    def parse_error
      load!
      @parser_error
    end

    private

    def load!
      return if @loaded

      @content = JSON.parse(File.read(@path))
    rescue JSON::ParserError => e
      @parser_error = e
    ensure
      @loaded = true
    end
  end
end
