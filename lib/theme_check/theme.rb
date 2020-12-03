# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    attr_reader :root

    def initialize(root)
      @root = Pathname.new(root)
    end

    def liquid
      @liquid ||= @root.glob("**/*.liquid").map { |path| Template.new(path, @root) }
    end

    def json
      @json ||= @root.glob("**/*.json").map { |path| JsonFile.new(path, @root) }
    end

    def all
      @all ||= json + liquid
    end

    def [](name)
      all.find { |t| t.name == name }
    end

    def templates
      liquid.select(&:template?)
    end

    def sections
      liquid.select(&:section?)
    end

    def snippets
      liquid.select(&:snippet?)
    end
  end
end
