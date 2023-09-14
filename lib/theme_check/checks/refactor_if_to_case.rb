# frozen_string_literal: true

module ThemeCheck
  # Suggest replacing a {% if x == a %}A{% elsif x == b %}B{% else %}C{% endif %} with a case statement.
  class RefactorIfToCase < LiquidCheck
    include LiquidHelper

    severity :style
    category :liquid

    def initialize(min_conditions: 3, min_branches: 2)
      @min_conditions = min_conditions
      @min_branches = min_branches
    end

    def on_if(node)
      return unless meets_thresholds?(node) && case_lookalike?(node)

      add_offense("Prefer using a case statement here instead", node: node)
    end

    private

    def meets_thresholds?(node)
      node.value.blocks.sum { |condition| subconditions(condition).size } >= @min_conditions &&
        node.value.nodelist.uniq.size >= @min_branches
    end

    def case_lookalike?(node)
      conditions = node.value.blocks.reject(&:else?)
      subconditions = conditions.flat_map { |condition| subconditions(condition) }
      relations = conditions.flat_map { |condition| condition_relations(condition) }
      lefts = subconditions.map(&:left)
      rights = subconditions.map(&:right)

      lefts.all?(Liquid::VariableLookup) &&
        lefts.map { |left| recover_variable_markup(left) }.uniq.size == 1 &&
        rights.all? { |right| right.is_a?(Integer) || right.is_a?(String) } &&
        subconditions.map(&:operator).map!(&:to_s).uniq == %w[==] &&
        relations.uniq.to_set <= %i[or].to_set
    end
  end
end
