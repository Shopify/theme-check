# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    DEFAULT_LOCALE_REGEXP = %r{^locales/(.*)\.default$}
    LIQUID_REGEX = /\.liquid$/i
    JSON_REGEX = /\.json$/i

    def initialize(storage)
      @storage = storage
    end

    def assets
      @assets ||= @storage.files
        .select { |path| path.start_with?("assets/") }
        .map { |path| AssetFile.new(path, @storage) }
    end

    def liquid
      @liquid ||= @storage.files
        .select { |path| LIQUID_REGEX.match?(path) }
        .map { |path| Template.new(path, @storage) }
    end

    def json
      @json ||= @storage.files
        .select { |path| JSON_REGEX.match?(path) }
        .map { |path| JsonFile.new(path, @storage) }
    end

    def directories
      @storage.directories
    end

    def default_locale_json
      return @default_locale_json if defined?(@default_locale_json)
      @default_locale_json = json.find do |json_file|
        json_file.name.match?(DEFAULT_LOCALE_REGEXP)
      end
    end

    def default_locale
      if default_locale_json
        default_locale_json.name[DEFAULT_LOCALE_REGEXP, 1]
      else
        "en"
      end
    end

    def all
      @all ||= json + liquid + assets
    end

    def [](name_or_relative_path)
      case name_or_relative_path
      when Pathname
        all.find { |t| t.relative_path == name_or_relative_path }
      else
        all.find { |t| t.name == name_or_relative_path }
      end
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
