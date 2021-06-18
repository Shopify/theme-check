# frozen_string_literal: true
module ThemeCheck
  class HtmlParsingError < HtmlCheck
    severity :error
    category :html
    doc docs_url(__FILE__)

    def on_parse_error(exception, template)
      add_offense("HTML in this template can not be parsed: #{exception.message}", template: template)
    end
  end
end
