# frozen_string_literal: true

module ThemeCheck
  # Suggest replacing an unless with an else branch with an if block.
  # Checks such as IfToDefaultPipeRefactor work on ifs only.
  class UnlessElse < LiquidCheck
    include LiquidHelper

    severity :suggestion
    category :liquid

    def on_unless(node)
      return if node.value.blocks.size == 1

      add_offense("Use if/elsif/else tags instead of unless/else", node: node)
    end
  end
end
