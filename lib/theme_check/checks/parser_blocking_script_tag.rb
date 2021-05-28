# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use parser-blocking script tags
  class ParserBlockingScriptTag < LiquidCheck
    severity :error
    categories :liquid, :performance
    doc docs_url(__FILE__)

    def on_variable(node)
      used_filters = node.value.filters.map { |name, *_rest| name }
      if used_filters.include?("script_tag")
        add_offense(
          "The script_tag filter is parser-blocking. Use a script tag with the async or defer " \
          "attribute for better performance",
          node: node
        )
      end
    end
  end
end
