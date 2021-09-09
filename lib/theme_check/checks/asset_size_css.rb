# frozen_string_literal: true
module ThemeCheck
  class AssetSizeCSS < HtmlCheck
    include RegexHelpers
    severity :error
    category :html, :performance
    doc docs_url(__FILE__)

    attr_reader :threshold_in_bytes

    def initialize(threshold_in_bytes: 100_000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_link(node)
      return if node.attributes['rel'] != "stylesheet"
      file_size = href_to_file_size(node.attributes['href'])
      return if file_size.nil?
      return if file_size <= threshold_in_bytes
      add_offense(
        "CSS on every page load exceeding compressed size threshold (#{threshold_in_bytes} Bytes)",
        node: node
      )
    end

    def href_to_file_size(href)
      # asset_url (+ optional stylesheet_tag) variables
      if href =~ /^#{LIQUID_VARIABLE}$/o && href =~ /asset_url/ && href =~ Liquid::QuotedString
        asset_id = Regexp.last_match(0).gsub(START_OR_END_QUOTE, "")
        asset = @theme.assets.find { |a| a.name.end_with?("/" + asset_id) }
        return if asset.nil?
        asset.gzipped_size

      # remote URLs
      elsif href =~ %r{^(https?:)?//}
        asset = RemoteAssetFile.from_src(href)
        asset.gzipped_size
      end
    end
  end
end
