# frozen_string_literal: true
module ThemeCheck
  class RemoteAsset < HtmlCheck
    severity :suggestion
    categories :html, :performance
    doc docs_url(__FILE__)

    TAGS = %w[img script link source]
    PROTOCOL = %r{(https?:)?//}
    ABSOLUTE_PATH = %r{\A/[^/]}im
    RELATIVE_PATH = %r{\A(?!#{PROTOCOL})[^/\{]}oim
    CDN_ROOT = "https://cdn.shopify.com/"

    def on_element(node)
      return unless TAGS.include?(node.name)

      resource_url = node.attributes["src"]&.value || node.attributes["href"]&.value
      return if resource_url.nil? || resource_url.empty?

      # Ignore if URL is Liquid, taken care of by AssetUrlFilters check
      return if resource_url.start_with?(CDN_ROOT)
      return if resource_url =~ ABSOLUTE_PATH
      return if resource_url =~ RELATIVE_PATH
      return if url_hosted_by_shopify?(resource_url)

      # Ignore non-stylesheet rel tags
      rel = node.attributes["rel"]
      return if rel && rel.value != "stylesheet"

      add_offense(
        "Asset should be served by the Shopify CDN for better performance.",
        node: node,
      )
    end

    private

    def url_hosted_by_shopify?(url)
      url.start_with?(Liquid::VariableStart) &&
        AssetUrlFilters::ASSET_URL_FILTERS.any? { |filter| url.include?(filter) }
    end
  end
end
