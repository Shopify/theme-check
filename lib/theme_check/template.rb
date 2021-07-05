# frozen_string_literal: true

module ThemeCheck
  class Template < ThemeFile
    def write
      content = updated_content
      if source != content
        @storage.write(@relative_path, content)
        @source = content
      end
    end

    def liquid?
      true
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
    def updated_content
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

    def self.parse(source)
      Tags.register_tags!
      Liquid::Template.parse(
        source,
        line_numbers: true,
        error_mode: :warn,
        disable_liquid_c_nodes: true,
      )
    end
  end
end
