# frozen_string_literal: true
module ThemeCheck
  class VariableName < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def on_assign(node)
      check_variable_name(node, node.value.to)
    end

    def on_variable(node)
      return unless node.value.name.is_a?(Liquid::VariableLookup)

      check_variable_name(node, node.value.name.name)
      node.value.name.lookups.each { |child| check_variable_name(node, child) }
    end

    private

    def check_variable_name(node, variable)
      variable = variable.name if variable.is_a?(Liquid::VariableLookup)

      return if variable.match?(/^[\d[[:lower:]]_]+$/)

      add_offense("Use snake_case for variable names", node: node)
    end
  end
end
