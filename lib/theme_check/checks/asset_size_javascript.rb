# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use too much JavaScript on page load
  # Encourages the use of the Import on Interaction pattern [1].
  # [1]: https://addyosmani.com/blog/import-on-interaction/
  class AssetSizeJavaScript < LiquidCheck
    include RegexHelpers
    severity :error
    category :performance
    doc docs_url(__FILE__)

    Script = Struct.new(:src, :match)

    TAG = /#{Liquid::TagStart}.*?#{Liquid::TagEnd}/om
    VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
    SCRIPT_TAG_SRC = %r{
      <script
        [^>]+                              # any non closing tag character
        src=                               # src attribute start
        (?<src>
          '(?:#{TAG}|#{VARIABLE}|[^']+)*'| # any combination of tag/variable or non straight quote inside straight quotes
          "(?:#{TAG}|#{VARIABLE}|[^"]+)*"  # any combination of tag/variable or non double quotes inside double quotes
        )
        [^>]*                              # any non closing character till the end
      >
    }omix

    attr_reader :threshold_in_bytes

    def initialize(threshold_in_bytes: 10000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_document(node)
      @node = node
      @source = node.template.source
      record_offenses
    end

    def record_offenses
      scripts(@source).each do |script|
        file_size = src_to_file_size(script.src)
        next if file_size.nil?
        next if file_size <= threshold_in_bytes
        add_offense(
          "JavaScript on every page load exceding compressed size threshold (#{threshold_in_bytes} Bytes), consider using the import on interaction pattern.",
          node: @node,
          markup: script.src,
          line_number: @source[0...script.match.begin(:src)].count("\n") + 1
        )
      end
    end

    def scripts(source)
      matches(source, SCRIPT_TAG_SRC)
        .map { |m| Script.new(m[:src].gsub(START_OR_END_QUOTE, ""), m) }
    end

    def src_to_file_size(src)
      # We're kind of intentionally only looking at {{ 'asset' | asset_url }} or full urls in here.
      # More complicated liquid statements are not in scope.
      if src =~ /^#{VARIABLE}$/o && src =~ /asset_url/ && src =~ Liquid::QuotedString
        asset_id = Regexp.last_match(0).gsub(START_OR_END_QUOTE, "")
        asset = @theme.assets.find { |a| a.name.ends_with?("/" + asset_id) }
        return if asset.nil?
        asset.gzipped_size
      elsif src =~ %r{^(https?:)?//}
        asset = RemoteAssetFile.from_src(src)
        asset.gzipped_size
      end
    end
  end
end
