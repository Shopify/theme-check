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

    def default_locale_json
      @default_locale_json ||= json.find do |json_file|
        json_file.relative_path.to_s.match(%r{locales/.*\.default})
      end
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
