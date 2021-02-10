# frozen_string_literal: true
require "json"
require "pathname"

module ThemeCheck
  class JsonFile
    def initialize(relative_path, storage)
      @relative_path = relative_path
      @storage = storage
      @loaded = false
      @content = nil
      @parser_error = nil
    end

    def path
      @storage.path(@relative_path)
    end

    def relative_path
      @relative_pathname ||= Pathname.new(@relative_path)
    end

    def content
      load!
      @content
    end

    def parse_error
      load!
      @parser_error
    end

    def name
      relative_path.sub_ext('').to_s
    end

    private

    def load!
      return if @loaded

      @content = JSON.parse(@storage.read(@relative_path))
    rescue JSON::ParserError => e
      @parser_error = e
    ensure
      @loaded = true
    end
  end
end
