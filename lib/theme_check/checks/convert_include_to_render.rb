# frozen_string_literal: true
module ThemeCheck
  # Recommends replacing `include` for `render`
  class ConvertIncludeToRender < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url("docs/checks/convert_include_to_render.md")

    def on_include(node)
      add_offense("`include` is deprecated - convert it to `render`", node: node)
    end
  end
end
