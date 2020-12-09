# frozen_string_literal: true
module ThemeCheck
  # Recommends replacing `include` for `render`
  class ConvertIncludeToRender < LiquidCheck
    severity :suggestion
    category :liquid
    doc "https://shopify.dev/docs/themes/liquid/reference/tags/deprecated-tags#include"

    def on_include(node)
      add_offense("`include` is deprecated - convert it to `render`", node: node)
    end
  end
end
