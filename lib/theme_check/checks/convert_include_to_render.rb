# frozen_string_literal: true
module ThemeCheck
  # Recommends replacing `include` for `render`
  class ConvertIncludeToRender < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def on_include(node)
      add_offense("`include` is deprecated - convert it to `render`", node: node) do |corrector|
        corrector.replace(node, "render \'#{node.value.template_name_expr}\' ")
      end
    end
  end
end
