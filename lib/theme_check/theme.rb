# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class Theme
    DEFAULT_LOCALE_REGEXP = %r{^locales/(.*)\.default$}

    # Expects to return an array of Template
    def liquid
      raise NotImplementedError
    end

    # Expects to return an array of JsonFile
    def json
      raise NotImplementedError
    end

    # Expects to return an array of directory names
    def directories
      raise NotImplementedError
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
