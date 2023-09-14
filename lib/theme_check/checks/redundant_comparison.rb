# frozen_string_literal: true

module ThemeCheck
  # Suggest replace { x == true } and { x != false } with just { x }
  class RedundantComparison < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    def on_condition(node)
      return unless standard_condition?(node.value) && redundant_comparison?(node.value)

      ancestor = non_condition_ancestor(node)
      condition_markup = recover_single_condition_markup(node.value)
      markup = ancestor.markup.include?(condition_markup) ? condition_markup : nil

      add_offense('Apparent redundant boolean comparison with true or false', node: ancestor, markup: markup)
    end

    private

    def redundant_comparison?(condition)
      case condition.operator
      when '==' then condition.right == true # ironic
      when '!=' then condition.right == false
      else false
      end
    end

    def non_condition_ancestor(node)
      node.value.is_a?(Liquid::Condition) ? non_condition_ancestor(node.parent) : node
    end
  end
end
