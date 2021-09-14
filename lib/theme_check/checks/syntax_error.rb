# frozen_string_literal: true
module ThemeCheck
  # Report Liquid syntax errors
  class SyntaxError < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    def on_document(node)
      node.theme_file.warnings.each do |warning|
        add_exception_as_offense(warning, theme_file: node.theme_file)
      end
    end

    def on_error(exception)
      add_exception_as_offense(exception, theme_file: theme[exception.template_name])
    end

    private

    def add_exception_as_offense(exception, theme_file:)
      add_offense(
        exception.to_s(false).sub(/ in ".*"$/, ''),
        line_number: exception.line_number,
        markup: exception.markup_context&.sub(/^in "(.*)"$/, '\1'),
        theme_file: theme_file,
      )
    end
  end
end
