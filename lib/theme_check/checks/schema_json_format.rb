# frozen_string_literal: true
module ThemeCheck
  class SchemaJsonFormat < LiquidCheck
    severity :style
    category :liquid
    doc docs_url(__FILE__)

    def initialize(start_level: 0, indent: '  ')
      @pretty_json_opts = {
        indent: indent,
        start_level: start_level,
      }
    end

    def on_schema(node)
      schema = node.inner_json
      return if schema.nil?
      pretty_schema = pretty_json(schema, **@pretty_json_opts)
      if pretty_schema != node.inner_markup
        add_offense(
          "JSON formatting could be improved",
          node: node,
        ) do |corrector|
          corrector.replace_inner_json(node, schema, **@pretty_json_opts)
        end
      end
    end
  end
end
