# frozen_string_literal: true

module ThemeCheck
  class InMemoryJsonFile < JsonFile
    attr_reader :content

    def initialize(path, content)
      @path = Pathname(path)
      @content = JSON.parse(content)
      @parser_error = nil
    rescue JSON::ParserError => e
      @parser_error = e
    end

    def relative_path
      @path
    end

    def parse_error
      @parser_error
    end
  end
end
