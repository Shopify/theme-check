# frozen_string_literal: true
module ThemeCheck
  class DeprecateBgsizes < HtmlCheck
    severity :suggestion
    category :html, :performance
    doc docs_url(__FILE__)

    def on_div(node)
      class_list = node.attributes["class"]&.value&.split(" ")
      add_offense("Use the native loading=\"lazy\" attribute instead of lazysizes", node: node) if class_list&.include?("lazyload")
      add_offense("Use the CSS imageset attribute instead of data-bgset", node: node) if node.attributes["data-bgset"]
    end
  end
end
