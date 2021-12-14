# frozen_string_literal: true
module ThemeCheck
  class AssetSizeCSSStylesheetTag < LiquidCheck
    include RegexHelpers
    severity :error
    category :liquid, :performance
    doc docs_url(__FILE__)

    def initialize(threshold_in_bytes: 100_000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_variable(node)
      used_filters = node.filters.map { |name, *_rest| name }
      return unless used_filters.include?("stylesheet_tag")
      file_size = stylesheet_tag_pipeline_to_file_size(node.markup)
      return if file_size.nil?
      return if file_size <= @threshold_in_bytes
      add_offense(
        "CSS on every page load exceeding compressed size threshold (#{@threshold_in_bytes} Bytes).",
        node: node
      )
    end

    def stylesheet_tag_pipeline_to_file_size(href)
      # asset_url
      if href =~ /asset_url/ && href =~ Liquid::QuotedString
        asset_id = Regexp.last_match(0).gsub(START_OR_END_QUOTE, "")
        asset = @theme.assets.find { |a| a.name.end_with?("/" + asset_id) }
        return if asset.nil?
        asset.gzipped_size

      # remote URLs
      elsif href =~ %r{(https?:)?//[^'"]+}
        url = Regexp.last_match(0)
        asset = RemoteAssetFile.from_src(url)
        asset.gzipped_size
      end
    end
  end
end
