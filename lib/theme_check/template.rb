# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Template
    # expects a Pathname instance
    def relative_path
      raise NotImplementedError
    end

    # expects a string
    def source
      raise NotImplementedError
    end

    # should do something with an updated source
    def write
      raise NotImplementedError
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

    def lines
      # Retain trailing newline character
      @lines ||= source.split("\n", -1)
    end

    # Not entirely obvious but lines is mutable, corrections are to be
    # applied on @lines.
    def updated_source
      lines.join("\n")
    end

    def excerpt(line)
      lines[line - 1].strip
    end

    def source_excerpt(line)
      original_lines = source.split("\n")
      original_lines[line - 1].strip
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

    def ==(other)
      other.is_a?(Template) && relative_path == other.relative_path
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
