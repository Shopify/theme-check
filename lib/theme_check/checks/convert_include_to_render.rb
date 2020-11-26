# frozen_string_literal: true
module ThemeCheck
  # Recommends replacing `include` for `render`
  class ConvertIncludeToRender < Check
    severity :suggestion

    def on_include(node)
      add_offense("`include` is deprecated - convert it to `render`", node: node)
    end
  end
end
