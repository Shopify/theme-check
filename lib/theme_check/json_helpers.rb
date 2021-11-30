# frozen_string_literal: true
module ThemeCheck
  module JsonHelpers
    def format_json_parse_error(error)
      message = error.message[/\d+: (.+)$/, 1] || 'Invalid syntax'
      "#{message} in JSON"
    end

    def pretty_json(hash, start_level: 1, indent: "  ")
      start_indent = indent * start_level

      <<~JSON

        #{start_indent}#{JSON.pretty_generate(
          hash,
          indent: indent,
          array_nl: "\n#{start_indent}",
          object_nl: "\n#{start_indent}",
        )}
      JSON
    end
  end
end
