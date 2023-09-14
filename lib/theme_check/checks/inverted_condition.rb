# frozen_string_literal: true

module ThemeCheck
  # Reject things like { 0 < product.stock } and { false == product.available }
  class InvertedCondition < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    def on_condition(node)
      return unless inverted_condition?(node.value)

      ancestor = non_condition_ancestor(node)
      condition_markup = recover_single_condition_markup(node.value)
      markup = ancestor.markup.include?(condition_markup) ? condition_markup : nil

      add_offense('Inverted condition, variable should appear on the left', node: ancestor, markup: markup)
    end

    private

    def non_condition_ancestor(node)
      node.value.is_a?(Liquid::Condition) ? non_condition_ancestor(node.parent) : node
    end
  end
end
