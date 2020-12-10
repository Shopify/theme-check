# frozen_string_literal: true
module ThemeCheck
  module JsonHelpers
    def format_json_parse_error(error)
      message = error.message[/\d+: (.+)$/, 1] || 'Invalid syntax'
      "#{message} in JSON"
    end
  end
end
