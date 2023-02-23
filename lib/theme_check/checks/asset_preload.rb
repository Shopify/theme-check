# frozen_string_literal: true
module ThemeCheck
  class AssetPreload < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    def on_link(node)
      return unless node.attributes["rel"]&.downcase == "preload"
      return if node.literal? # literal urls cannot use the preload_tag
      return unless node.attributes["href"]&.match?(/(?:assets?|image|file)_url\b/i)
      case node.attributes["as"]&.downcase
      when "font"
        # fonts are not supported yet
      when "style"
        add_offense("For better performance, prefer using the preload argument of the stylesheet_tag filter", node: node)
      when "image"
        add_offense("For better performance, prefer using the preload argument of the image_tag filter", node: node)
      else
        add_offense("For better performance, prefer using the preload_tag filter", node: node)
      end
    end
  end
end
