# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class URIHelperTest < Minitest::Test
      include URIHelper

      def test_file_path_behaves_as_expected
        assert_equal("/Users/foo", file_path("file:///Users/foo"))
        assert_equal("C:/Users/bar", file_path("file:///C%3A/Users/bar"))
      end

      def test_file_uri_behaves_as_expected
        assert_equal("file:///Users/foo", file_uri("/Users/foo"))
        assert_equal("file:///C%3A/Users/bar", file_uri("C:/Users/bar"))
      end

      def test_file_path_should_be_the_inverse_file_uri
        assert_equal("/Users/foo", file_path(file_uri("/Users/foo")))
        assert_equal("C:/Users/bar", file_path(file_uri("C:/Users/bar")))
      end

      def test_file_uri_should_be_the_inverse_of_file_path
        assert_equal("file:///Users/foo", file_uri(file_path("file:///Users/foo")))
        assert_equal("file:///C%3A/Users/bar", file_uri(file_path("file:///C%3A/Users/bar")))
      end
    end
  end
end
