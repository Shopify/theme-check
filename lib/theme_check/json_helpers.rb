# frozen_string_literal: true
module ThemeCheck
  module JsonHelpers
    def format_json_parse_error(error)
      message = error.message[/\d+: (.+)$/, 1] || 'Invalid syntax'
      "#{message} in JSON"
    end

    def pretty_json(hash, level = 1)
      indent = "  " * level
      <<~JSON

        #{indent}#{JSON.pretty_generate(
          hash,
          array_nl: "\n#{indent}",
          object_nl: "\n#{indent}",
        )}
      JSON
    end
  end
end
