# frozen_string_literal: true
module ThemeCheck
  class AssetSizeCSS < LiquidCheck
    include RegexHelpers
    severity :error
    category :performance
    doc docs_url(__FILE__)

    Link = Struct.new(:href, :index)

    TAG = /#{Liquid::TagStart}.*?#{Liquid::TagEnd}/om
    VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
    LINK_TAG_HREF = %r{
      <link
        (?=(?:[^>]|\n|\r)+?rel=['"]?stylesheet['"]?)+?  # Make sure rel=stylesheet is in the link with lookahead
        [^>]+                                           # any non closing tag character
        href=                                           # href attribute start
        (?<href>
          '(?:#{TAG}|#{VARIABLE}|[^']+)*'|              # any combination of tag/variable or non straight quote inside straight quotes
          "(?:#{TAG}|#{VARIABLE}|[^"]+)*"               # any combination of tag/variable or non double quotes inside double quotes
        )
        [^>]*                                           # any non closing character till the end
      >
    }omix
    STYLESHEET_TAG = %r{
      #{Liquid::VariableStart}          # VariableStart
      (?:(?!#{Liquid::VariableEnd}).)*? # anything that isn't followed by a VariableEnd
      \|\s*asset_url\s*                 # | asset_url
      \|\s*stylesheet_tag\s*            # | stylesheet_tag
      #{Liquid::VariableEnd}            # VariableEnd
    }omix

    attr_reader :threshold_in_bytes

    def initialize(threshold_in_bytes: 100_000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_document(node)
      @node = node
      @source = node.template.source
      record_offenses
    end

    def record_offenses
      stylesheets(@source).each do |stylesheet|
        file_size = href_to_file_size(stylesheet.href)
        next if file_size.nil?
        next if file_size <= threshold_in_bytes
        add_offense(
          "CSS on every page load exceding compressed size threshold (#{threshold_in_bytes} Bytes).",
          node: @node,
          markup: stylesheet.href,
          line_number: @source[0...stylesheet.index].count("\n") + 1
        )
      end
    end

    def stylesheets(source)
      stylesheet_links = matches(source, LINK_TAG_HREF)
        .map do |m|
          Link.new(
            m[:href].gsub(START_OR_END_QUOTE, ""),
            m.begin(:href),
          )
        end

      stylesheet_tags = matches(source, STYLESHEET_TAG)
        .map do |m|
          Link.new(
            m[0],
            m.begin(0),
          )
        end

      stylesheet_links + stylesheet_tags
    end

    def href_to_file_size(href)
      # asset_url (+ optional stylesheet_tag) variables
      if href =~ /^#{VARIABLE}$/o && href =~ /asset_url/ && href =~ Liquid::QuotedString
        asset_id = Regexp.last_match(0).gsub(START_OR_END_QUOTE, "")
        asset = @theme.assets.find { |a| a.name.ends_with?("/" + asset_id) }
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
