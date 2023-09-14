# frozen_string_literal: true

module ThemeCheck
  # Suggest replacing {% if x != blank %}{{x}}{% else %}Default{% endif %} with {{x | default: 'Default'}}
  class RefactorIfToDefaultPipe < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    def on_if(node)
      return unless ifelse?(node) && can_convert_to_default_pipe?(node)

      add_offense("Use default pipe instead of if/else", node: node)
    end

    private

    def can_convert_to_default_pipe?(node)
      condition = node.value.blocks.first
      nodelists = node.value.nodelist.map { |branch| stripped_nodelist(branch.nodelist) }
      body = nodelists[0].first

      not_blank_condition?(condition) &&
        single_liquid_variable_nodelist?(nodelists[0]) &&
        body.filters.empty? &&
        body.name.is_a?(Liquid::VariableLookup) &&
        nodelists[1].all?(String) &&
        recover_variable_markup(condition.left) == recover_variable_markup(body.name)
    end

    def ifelse?(node)
      node.value.nodelist.size == 2 && node.value.blocks[1].else?
    end

    def single_line_string_nodelist?(nodelist)
      nodelist.all?(String) && !nodelist.join.strip.include?("\n")
    end

    def single_liquid_variable_nodelist?(nodelist)
      nodelist.size == 1 && nodelist.all?(Liquid::Variable)
    end
  end
end
