# frozen_string_literal: true

module ThemeCheck
  # Suggest replacing a {% if collection != empty %}{% for x in collection %}...{% endfor %}{% else %}...{% endif %} with for-else construct.
  class RefactorIfForToForElse < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    def on_if(node)
      return unless ifelse?(node) && can_convert_to_for_else?(node)

      add_offense("Can replace if-for-else-endif construct with simpler for-else-endfor construct", node: node)
    end

    private

    def ifelse?(node)
      node.value.nodelist.size == 2 && node.value.blocks[1].else?
    end

    def can_convert_to_for_else?(node)
      condition = node.value.blocks.first
      nodelists = node.value.nodelist.map { |branch| stripped_nodelist(branch.nodelist) }
      body = nodelists[0].first

      positive_size_condition?(condition) &&
        single_for_loop_nodelist?(nodelists[0]) &&
        body.collection_name.is_a?(Liquid::VariableLookup) &&
        recover_variable_markup_without_size(condition.left) == recover_variable_markup(body.collection_name)
    end

    def recover_variable_markup_without_size(variable_lookup)
      recover_variable_markup(variable_lookup).sub(/\.size$/, '')
    end

    def single_for_loop_nodelist?(nodelist)
      nodelist.size == 1 && nodelist.first.is_a?(Liquid::For)
    end
  end
end
