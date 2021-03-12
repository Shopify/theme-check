# frozen_string_literal: true
module ThemeCheck
  class ValidJson < JsonCheck
    severity :error
    category :json
    doc docs_url(__FILE__)

    def on_file(file)
      if file.parse_error
        message = format_json_parse_error(file.parse_error)
        add_offense(message, template: file)
      end
    end
  end
end
