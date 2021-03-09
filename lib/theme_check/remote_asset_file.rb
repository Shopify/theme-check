# frozen_string_literal: true
require "net/http"
require "pathname"
require "zlib"

module ThemeCheck
  class RemoteAssetFile
    class << self
      def cache
        @cache ||= {}
      end

      def from_src(src)
        key = uri(src).to_s
        cache[key] = RemoteAssetFile.new(src) unless cache.key?(key)
        cache[key]
      end

      def uri(src)
        URI.parse(src.sub(%r{^//}, "https://"))
      end
    end

    def initialize(src)
      @uri = RemoteAssetFile.uri(src)
    end

    def content
      @content ||= Net::HTTP.get(@uri)
    end

    def gzipped_size
      @gzipped_size ||= Zlib.gzip(content).size
    end
  end
end
