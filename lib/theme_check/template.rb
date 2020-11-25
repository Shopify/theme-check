# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Template
    attr_reader :path

    def initialize(path, root)
      @path = Pathname(path)
      @root = Pathname(root)
    end

    def relative_path
      @path.relative_path_from(@root)
    end

    def name
      relative_path.sub_ext('').to_s
    end

    def template?
      name.start_with?('templates')
    end

    def section?
      name.start_with?('sections')
    end

    def snippet?
      name.start_with?('snippets')
    end

    def source
      @source ||= @path.read
    end

    def excerpt(line)
      source.split("\n")[line - 1].strip
    end

    def parse
      @ast ||= self.class.parse(source)
    end

    def errors
      @ast.errors
    end

    def root
      parse.root
    end

    def self.parse(source)
      Liquid::Template.parse(
        source,
        line_numbers: true,
        error_mode: :strict,
      )
    end
  end
end
