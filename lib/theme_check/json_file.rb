# frozen_string_literal: true
require "json"

module ThemeCheck
  class JsonFile < ThemeFile
    def initialize(relative_path, storage)
      super
      @loaded = false
      @content = nil
      @parser_error = nil
    end

    def content
      load!
      @content
    end

    def parse_error
      load!
      @parser_error
    end

    def json?
      true
    end

    private

    def load!
      return if @loaded

      @content = JSON.parse(source)
    rescue JSON::ParserError => e
      @parser_error = e
    ensure
      @loaded = true
    end
  end
end
