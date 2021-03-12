# frozen_string_literal: true
module ThemeCheck
  # Report Liquid syntax errors
  class SyntaxError < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    def on_document(node)
      node.template.warnings.each do |warning|
        add_exception_as_offense(warning, template: node.template)
      end
    end

    def on_error(exception)
      add_exception_as_offense(exception, template: theme[exception.template_name])
    end

    private

    def add_exception_as_offense(exception, template:)
      add_offense(
        exception.to_s(false).sub(/ in ".*"$/, ''),
        line_number: exception.line_number,
        markup: exception.markup_context&.sub(/^in "(.*)"$/, '\1'),
        template: template,
      )
    end
  end
end
