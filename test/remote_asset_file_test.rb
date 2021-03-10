# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class RemoteAssetFileTest < Minitest::Test
    FakeResponse = Struct.new(:body)
    def setup
      @src = 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js'
      @asset = RemoteAssetFile.from_src(@src)
    end

    def test_instance_caching
      assert_equal(RemoteAssetFile.from_src(@src), RemoteAssetFile.from_src(@src))
      refute_equal(RemoteAssetFile.from_src(@src), RemoteAssetFile.from_src(@src + '?cachebust=1234'))
    end

    def test_network_request
      Net::HTTP.any_instance
        .expects(:request)
        .with { |req| req['Accept-Encoding'] == 'gzip, deflate, br' }
        .returns(FakeResponse.new("..."))
      assert_equal("...", @asset.content)
      assert_equal(3, @asset.gzipped_size)
    end
  end
end
