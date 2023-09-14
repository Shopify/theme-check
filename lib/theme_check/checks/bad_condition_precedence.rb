# frozen_string_literal: true

module ThemeCheck
  class BadConditionPrecedence < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    PRECEDENCE_MESSAGE = 'Composite conditions are evaluated right-to-left. The evaluation order of this condition might be unexpected'

    def on_condition(node)
      return if node.parent.value.is_a?(Liquid::Condition)

      operators = condition_relations(node.value)
      canonical = Array.new(operators.count(:or), :or) + Array.new(operators.count(:and), :and)
      return if canonical == operators

      add_offense(PRECEDENCE_MESSAGE, node: node.parent)
    end
  end
end
