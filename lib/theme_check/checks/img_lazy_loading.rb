# frozen_string_literal: true
module ThemeCheck
  class ImgLazyLoading < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    ACCEPTED_LOADING_VALUES = %w[lazy eager]

    def on_img(node)
      loading = node.attributes["loading"]&.value&.downcase
      return if ACCEPTED_LOADING_VALUES.include?(loading)

      class_list = node.attributes["class"]&.value&.split(" ")

      if class_list&.include?("lazyload")
        add_offense("Use the native loading=\"lazy\" attribute instead of lazysizes", node: node)
      elsif loading == "auto"
        add_offense("Prefer loading=\"lazy\" to defer loading of images", node: node)
      else
        add_offense("Add a loading=\"lazy\" attribute to defer loading of images", node: node)
      end
    end
  end
end
