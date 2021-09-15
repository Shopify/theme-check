# frozen_string_literal: true

module ThemeCheck
  class LiquidFile < ThemeFile
    def write
      content = rewriter.to_s
      if source != content
        @storage.write(@relative_path, content.gsub("\n", @eol))
        @source = content
        @rewriter = nil
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

    def rewriter
      @rewriter ||= ThemeFileRewriter.new(@relative_path, source)
    end

    def source_excerpt(line)
      original_lines = source.split("\n")
      original_lines[line - 1].strip
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
