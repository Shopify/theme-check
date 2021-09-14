# frozen_string_literal: true
module ThemeCheck
  # Recommends replacing `include` for `render`
  class ConvertIncludeToRender < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def on_include(node)
      add_offense("`include` is deprecated - convert it to `render`", node: node) do |corrector|
        # We need to fix #445 and pass the variables from the context or don't replace at all.
        # corrector.replace(node, "render \'#{node.value.template_name_expr}\' ")
      end
    end
  end
end
