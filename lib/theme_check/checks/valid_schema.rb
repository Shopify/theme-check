# frozen_string_literal: true
module ThemeCheck
  class ValidSchema < LiquidCheck
    severity :error
    category :json
    doc docs_url(__FILE__)

    def on_schema(node)
      JSON.parse(node.inner_markup)
    rescue JSON::ParserError => e
      add_offense(format_json_parse_error(e), node: node)
    end
  end
end
