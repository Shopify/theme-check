# frozen_string_literal: true

module ThemeCheck
  # Reports deeply nested {% for ... %} loops.
  class NestedLoop < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    def initialize(max_nesting_level: 2)
      @current_nesting_level = 0
      @max_nesting_level = max_nesting_level
    end

    def on_for(node)

      @current_nesting_level += 1
      return if @current_nesting_level <= @max_nesting_level

      add_offense("Avoid nesting loops more than #{@max_nesting_level} levels", node: node)
    end

    def after_tag(node)
      return unless node.value.is_a?(::Liquid::For)

      @current_nesting_level -= 1
    end
  end
end
