# frozen_string_literal: true

require "benchmark"
require "uri"
require "cgi"

module ThemeCheck
  module LanguageServer
    module URIHelper
      # Will URI.encode a string the same way VS Code would. There are two things
      # to watch out for:
      #
      # 1. VS Code still uses the outdated '%20' for spaces
      # 2. VS Code prefixes Windows paths with / (so /C:/Users/... is expected)
      #
      # Exists because of https://github.com/Shopify/theme-check/issues/360
      def file_uri(absolute_path)
        return if absolute_path.nil?
        "file://" + absolute_path
          .to_s
          .split('/')
          .map { |x| CGI.escape(x).gsub('+', '%20') }
          .join('/')
          .sub(%r{^/?}, '/') # Windows paths should be prefixed by /c:
      end

      def file_path(uri_string)
        return if uri_string.nil?
        uri = URI(uri_string)
        path = CGI.unescape(uri.path)
        # On Windows, VS Code sends the URLs as file:///C:/...
        # /C:/1234 is not a valid path in ruby. So we strip the slash.
        path = path.sub(%r{^/([a-z]:/)}i, '\1')
        path
      end
    end
  end
end
