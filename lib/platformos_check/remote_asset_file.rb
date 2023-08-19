# frozen_string_literal: true
require "net/http"
require "pathname"

module PlatformosCheck
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
      rescue URI::InvalidURIError
        nil
      end
    end

    def initialize(src)
      @uri = RemoteAssetFile.uri(src)
      @content = nil
    end

    def content
      return if @uri.nil?
      return @content unless @content.nil?

      @content = request(@uri)

    rescue OpenSSL::SSL::SSLError, Zlib::StreamError, *NET_HTTP_EXCEPTIONS
      @contents = ''
    end

    def gzipped_size
      return if @uri.nil?
      @gzipped_size ||= content.bytesize
    end

    private

    def request(uri)
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        req = Net::HTTP::Get.new(uri)
        req['Accept-Encoding'] = 'gzip, deflate, br'
        http.request(req)
      end

      res.body
    end
  end
end
