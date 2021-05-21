# frozen_string_literal: true
module ThemeCheck
  class ContentForHeaderModification < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    def initialize
      @in_assign = false
      @in_capture = false
    end

    def on_variable(node)
      return unless node.value.name.is_a?(Liquid::VariableLookup)
      return unless node.value.name.name == "content_for_header"

      if @in_assign || @in_capture || node.value.filters.any?
        add_offense(
          "Do not rely on the content of `content_for_header`",
          node: node,
        )
      end
    end

    def on_assign(_node)
      @in_assign = true
    end

    def after_assign(_node)
      @in_assign = false
    end

    def on_capture(_node)
      @in_capture = true
    end

    def after_capture(_node)
      @in_capture = false
    end
  end
end
