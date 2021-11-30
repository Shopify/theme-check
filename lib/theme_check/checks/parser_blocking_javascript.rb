# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use parser-blocking script tags
  class ParserBlockingJavaScript < HtmlCheck
    severity :error
    categories :html, :performance
    doc docs_url(__FILE__)

    def on_script(node)
      return unless node.attributes["src"]
      return if node.attributes["defer"] || node.attributes["async"] || node.attributes["type"] == "module"

      add_offense("Missing async or defer attribute on script tag", node: node) do
        script = %r{(?<script_open><script)(?<attributes>(.|\n)*?)(?<script_close></script>)}m.match(node.source, node.source.index(node.parseable_markup))
        node.source.insert(script.begin(:attributes), " defer")
      end
    end
  end
end
