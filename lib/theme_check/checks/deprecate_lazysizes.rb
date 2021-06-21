# frozen_string_literal: true
module ThemeCheck
  class DeprecateLazysizes < HtmlCheck
    severity :suggestion
    category :html, :performance
    doc docs_url(__FILE__)

    def on_img(node)
      class_list = node.attributes["class"]&.value&.split(" ")
      add_offense("Use the native loading=\"lazy\" attribute instead of lazysizes", node: node) if class_list&.include?("lazyload")
      add_offense("Use the native srcset attribute instead of data-srcset", node: node) if node.attributes["data-srcset"]
      add_offense("Use the native sizes attribute instead of data-sizes", node: node) if node.attributes["data-sizes"]
      add_offense("Do not set the data-sizes attribute to auto", node: node) if node.attributes["data-sizes"]&.value == "auto"
    end
  end
end
