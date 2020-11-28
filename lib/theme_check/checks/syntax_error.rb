# frozen_string_literal: true
module ThemeCheck
  # Report Liquid syntax errors
  class SyntaxError < Check
    severity :error

    def on_document(node)
      node.template.warnings.each do |warning|
        add_offense(warning.to_s(false), node: warning, template: node.template)
      end
    end

    def on_error(exception)
      add_offense(exception.to_s(false), node: exception, template: theme[exception.template_name])
    end
  end
end
