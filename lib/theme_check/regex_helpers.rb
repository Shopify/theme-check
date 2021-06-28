# frozen_string_literal: true

module ThemeCheck
  module RegexHelpers
    VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
    def matches(s, re)
      start_at = 0
      matches = []
      while (m = s.match(re, start_at))
        matches.push(m)
        start_at = m.end(0)
      end
      matches
    end

    def href_to_file_size(href)
      # asset_url (+ optional stylesheet_tag) variables
      if href =~ /^#{VARIABLE}$/o && href =~ /asset_url/ && href =~ Liquid::QuotedString
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
