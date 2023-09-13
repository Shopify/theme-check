# frozen_string_literal: true

module ThemeCheck
  class BadConditionPrecedence < LiquidCheck
    severity :style
    category :liquid

    PRECEDENCE_MESSAGE = 'Composite conditions are evaluated right-to-left, which does not match standard evaluation order in this case'

    def on_condition(node)
      check_trivial_comparison(node)
      check_operator_precedence(node) unless node.parent.value.is_a?(Liquid::Condition)
    end

    private

    def check_trivial_comparison(node)
      condition = node.value
      ancestor = closest_if(node)
      add_offense('Check type and remove "== true"', node: ancestor) if condition.operator == '==' && condition.right == true
      add_offense('Check type and remove "!= false"', node: ancestor) if condition.operator == '!=' && condition.right == false
    end

    def check_operator_precedence(node)
      operators = JumpsellerLiquidx.condition_relations(node.value)
      canonical = Array.new(operators.count(:or), :or) + Array.new(operators.count(:and), :and)
      return if canonical == operators

      add_offense(PRECEDENCE_MESSAGE, node: node.parent)
    end

    def closest_if(node)
      node = node.parent while node.value.is_a?(Liquid::Condition)
      node
    end
  end
end
