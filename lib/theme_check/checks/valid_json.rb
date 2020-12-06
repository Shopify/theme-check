# frozen_string_literal: true
module ThemeCheck
  class ValidJson < JsonCheck
    severity :error

    def on_file(file)
      if file.parse_error
        message = file.parse_error.message[/\d+: (.+) at/, 1] || 'Invalid syntax'
        add_offense("#{message} in JSON", template: file)
      end
    end
  end
end
