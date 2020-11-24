# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    attr_reader :root

    def initialize(root)
      @root = Pathname.new(root)
    end

    def all
      @all ||= @root.glob("**/*.liquid").map { |path| Template.new(path) }
    end

    def [](name)
      all.find { |t| t.name == name }
    end

    def templates
      all.select(&:template?)
    end

    def sections
      all.select(&:section?)
    end

    def snippets
      all.select(&:snippet?)
    end
  end
end
