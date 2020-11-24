# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Template
    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def relative_path
      @path.relative_path_from(@path.parent.parent)
    end

    def name
      relative_path.sub_ext('').to_s
    end

    def dirname
      @path.parent.basename.to_s
    end

    def template?
      dirname == 'templates'
    end

    def section?
      dirname == 'sections'
    end

    def snippet?
      dirname == 'snippets'
    end

    def source
      @source ||= @path.read
    end

    def excerpt(line)
      source.split("\n")[line - 1].strip
    end

    def parse
      @ast ||= Liquid::Template.parse(
        source,
        line_numbers: true,
        disable_liquid_c_nodes: true
      )
    end

    def root
      parse.root
    end
  end
end
