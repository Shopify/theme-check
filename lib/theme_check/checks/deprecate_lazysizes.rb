# frozen_string_literal: true
module ThemeCheck
  class DeprecateLazysizes < HtmlCheck
    severity :suggestion
    category :html, :performance
    doc docs_url(__FILE__)

    def on_img(node)
      class_list = node.attributes["class"]&.split(" ")
      has_loading_lazy = node.attributes["loading"] == "lazy"
      has_native_source = node.attributes["src"] || node.attributes["srcset"]
      return if has_native_source && has_loading_lazy
      has_lazysize_source = node.attributes["data-srcset"] || node.attributes["data-src"]
      has_lazysize_class = class_list&.include?("lazyload")
      return unless has_lazysize_class && has_lazysize_source
      add_offense("Use the native loading=\"lazy\" attribute instead of lazysizes", node: node) if class_list&.include?("lazyload")
    end
  end
end
