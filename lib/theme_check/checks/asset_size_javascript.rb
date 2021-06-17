# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use too much JavaScript on page load
  # Encourages the use of the Import on Interaction pattern [1].
  # [1]: https://addyosmani.com/blog/import-on-interaction/
  class AssetSizeJavaScript < HtmlCheck
    include RegexHelpers
    severity :error
    category :html, :performance
    doc docs_url(__FILE__)

    attr_reader :threshold_in_bytes

    def initialize(threshold_in_bytes: 10000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_script(node)
      file_size = src_to_file_size(node.attributes['src']&.value)
      return if file_size.nil?
      return if file_size <= threshold_in_bytes
      add_offense(
        "JavaScript on every page load exceeds compressed size threshold (#{threshold_in_bytes} Bytes), consider using the import on interaction pattern.",
        node: node
      )
    end

    def src_to_file_size(src)
      # We're kind of intentionally only looking at {{ 'asset' | asset_url }} or full urls in here.
      # More complicated liquid statements are not in scope.
      if src =~ /^#{VARIABLE}$/o && src =~ /asset_url/ && src =~ Liquid::QuotedString
        asset_id = Regexp.last_match(0).gsub(START_OR_END_QUOTE, "")
        asset = @theme.assets.find { |a| a.name.end_with?("/" + asset_id) }
        return if asset.nil?
        asset.gzipped_size
      elsif src =~ %r{^(https?:)?//}
        asset = RemoteAssetFile.from_src(src)
        asset.gzipped_size
      end
    end
  end
end
