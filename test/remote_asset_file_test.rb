# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class RemoteAssetFileTest < Minitest::Test
    def setup
      @src = 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js'
      @asset = RemoteAssetFile.from_src(@src)
    end

    def test_instance_caching
      assert_equal(RemoteAssetFile.from_src(@src), RemoteAssetFile.from_src(@src))
      refute_equal(RemoteAssetFile.from_src(@src), RemoteAssetFile.from_src(@src + '?cachebust=1234'))
    end

    def test_network_request
      @asset.expects(:request).with(uri).returns("...")

      assert_equal("...", @asset.content)
      assert_equal(3, @asset.gzipped_size)
    end

    def test_handles_invalid_uris
      asset = RemoteAssetFile.from_src("https://{{ settings.url }}")
      refute(asset.gzipped_size)
      refute(asset.content)
    end

    def test_handles_eaddr_not_avail_errors
      asset = RemoteAssetFile.from_src("https://localhost:0/packs/embed.js")
      assert(asset.gzipped_size == 0)
      assert(asset.content.empty?)
    end

    private

    def uri
      RemoteAssetFile.uri(@src)
    end
  end
end
