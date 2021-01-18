# frozen_string_literal: true
module ThemeCheck
  class DeprecatedFilter < LiquidCheck
    doc "https://shopify.dev/docs/themes/liquid/reference/filters/deprecated-filters"
    category :liquid
    severity :suggestion

    def on_variable(node)
      used_filters = node.value.filters.map { |name, *_rest| name }
      used_filters.each do |filter|
        alternatives = ShopifyLiquid::DeprecatedFilter.alternatives(filter)
        next unless alternatives

        alternatives = alternatives.map { |alt| "`#{alt}`" }
        add_offense(
          "Deprecated filter `#{filter}`, consider using an alternative: #{alternatives.join(', ')}",
          node: node,
        )
      end
    end
  end
end
