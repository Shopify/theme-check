# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class CompletionProviderTest < Minitest::Test
      def setup
        super
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_find_token
        content = <<~LIQUID
          <head>
            {% rend %}
            <script src="{{ 'foo.js' |  }}"></script>
            {% rend
          </head>
        LIQUID
        provider = make_provider(filename => content)

        assert_can_find_token(provider, content, "{% rend %}")
        assert_can_find_token(provider, content, "{{ 'foo.js' |  }}")
        assert_can_find_token(provider, content, "<head>\n  ")
        assert_can_find_token(provider, content, "\"></script>\n  ")
        assert_can_find_token(provider, content, "{% rend\n</head>\n")
      end

      def test_doc_hash
        expected_hash = {
          documentation: {
            kind: "markdown",
            value: "### content",
          },
        }
        actual_hash = make_provider.doc_hash('### content')

        assert_equal(expected_hash, actual_hash)
      end

      def test_doc_hash_with_empty_content
        assert_equal({}, make_provider.doc_hash(nil))
        assert_equal({}, make_provider.doc_hash(''))
      end

      private

      def make_provider(files = {})
        storage = InMemoryStorage.new(files)
        CompletionProvider.new(storage)
      end

      def filename
        "layout/theme.liquid"
      end

      def assert_can_find_token(provider, content, token)
        # Being on the first character of a token should try to
        # complete the previous one
        refute_equal(token, provider.find_token(content, content.index(token))&.content)

        # Being inside the token should give you the token
        assert_equal(token, provider.find_token(content, content.index(token) + 1).content)

        # Being on the next character (outside the token) should give you the previous one.
        assert_equal(token, provider.find_token(content, content.index(token) + token.size).content)
      end
    end
  end
end
