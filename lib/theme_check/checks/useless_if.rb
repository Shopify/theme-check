# frozen_string_literal: true

module ThemeCheck
  # Suggest replacing {% if x != blank %}{{x}}{% endif %} with just {{x}}
  class UselessIf < LiquidCheck
    include LiquidHelper

    severity :suggestion
    category :liquid

    def on_if(node)
      return unless simple_if?(node) && if_is_useless?(node)

      add_offense('Conditional appears redundant, did you forget an html element?', node: node)
    end

    private

    def simple_if?(node)
      node.value.nodelist.size == 1
    end

    def if_is_useless?(node)
      condition = node.value.blocks.first
      nodelist = stripped_nodelist(node.value.nodelist.first.nodelist)
      body = nodelist.first

      nodelist.size == 1 &&
        body.is_a?(Liquid::Variable) &&
        body.filters.empty? &&
        body.name.is_a?(Liquid::VariableLookup) &&
        condition.child_condition.nil? &&
        recover_variable_markup(condition.left) == recover_variable_markup(body.name)
    end
  end
end
