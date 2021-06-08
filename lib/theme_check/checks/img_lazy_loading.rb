# frozen_string_literal: true
module ThemeCheck
  class ImgLazyLoading < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    def on_img(node)
      if node.attributes["loading"]&.value&.downcase != "lazy"
        add_offense("Add loading=\"lazy\" to defer loading of images", node: node)
      end
    end
  end
end
