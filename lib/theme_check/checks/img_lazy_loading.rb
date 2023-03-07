# frozen_string_literal: true
module ThemeCheck
  class ImgLazyLoading < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    ACCEPTED_LOADING_VALUES = %w[lazy eager]

    def on_img(node)
      loading = node.attributes["loading"]&.downcase
      return if ACCEPTED_LOADING_VALUES.include?(loading)
      add_offense("Use loading=\"eager\" for images visible in the viewport on load and loading=\"lazy\" for others", node: node)
    end
  end
end
