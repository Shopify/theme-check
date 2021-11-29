# frozen_string_literal: true
module ThemeCheck
  class SchemaJsonFormat < LiquidCheck
    severity :style
    category :liquid
    doc docs_url(__FILE__)

    def on_schema(node)
      schema = node.inner_json
      pretty_schema = pretty_json(schema)
      if pretty_schema != node.inner_markup
        add_offense(
          "JSON formatting could use some love",
          node: node,
        ) do |corrector|
          corrector.replace_inner_json(node, schema)
        end
      end
    rescue JSON::ParserError
      # Ignored, handled in ValidSchema.
    end
  end
end
