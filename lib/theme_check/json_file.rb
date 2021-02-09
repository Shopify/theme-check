# frozen_string_literal: true
require "json"
require "pathname"

module ThemeCheck
  class JsonFile
    # expects a Pathname instance
    def relative_path
      raise NotImplementedError
    end

    # expects a hash
    def content
      raise NotImplementedError
    end

    # expects a JSON::ParserError
    def parse_error
      raise NotImplementedError
    end

    def name
      relative_path.sub_ext('').to_s
    end
  end
end
