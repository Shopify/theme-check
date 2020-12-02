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

    def lines
      @lines ||= source.split("\n")
    end

    def excerpt(line)
      lines[line - 1].strip
    end

    def full_line(line)
      lines[line - 1]
    end

    def parse
      @ast ||= self.class.parse(source)
    end

    def warnings
      @ast.warnings
    end

    def root
      parse.root
    end

    def self.parse(source)
      Liquid::Template.parse(
        source,
        line_numbers: true,
        error_mode: :warn,
      )
    end
  end
end
