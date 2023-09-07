# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    LIQUID_REGEX = /\.liquid$/i
    JSON_REGEX = /\.json$/i

    attr_reader :storage

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
        .map { |path| LiquidFile.new(path, @storage) }
    end

    def json
      @json ||= @storage.files
        .select { |path| JSON_REGEX.match?(path) }
        .map { |path| JsonFile.new(path, @storage) }
    end

    def directories
      @storage.directories
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

    def components
      liquid.select(&:component?)
    end

    def partials
      liquid.select(&:partial?)
    end
  end
end
