# frozen_string_literal: true
module ThemeCheck
  # Report Liquid strict parse errors
  class ParseError < Check
    severity :error

    def on_error(exception)
      add_offense(exception.to_s(false), node: exception, template: theme[exception.template_name])
    end
  end
end
