# frozen_string_literal: true
module PlatformosCheck
  class CdnPreconnect < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    def on_link(node)
      return if node.attributes["rel"]&.downcase != "preconnect"
      return unless node.attributes["href"]&.downcase&.include?("cdn.shopify.com")
      add_offense("Preconnecting to cdn.shopify.com is unnecessary and can lead to worse performance", node: node)
    end
  end
end
