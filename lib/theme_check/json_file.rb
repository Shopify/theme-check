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

    def update_contents(new_content = {})
      raise ArgumentError if new_content.is_a?(String)
      @content = new_content
    end

    def write
      pretty = JSON.pretty_generate(@content)
      if source.rstrip != pretty.rstrip
        # Most editors add a trailing \n at the end of files. Here we
        # try to maintain the convention.
        eof = source.end_with?("\n") ? "\n" : ""
        @storage.write(@relative_path, pretty.gsub("\n", @eol) + eof)
        @source = pretty
      end
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
