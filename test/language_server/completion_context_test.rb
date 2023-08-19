# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class CompletionContextTest < Minitest::Test
      def setup
        super
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_buffer
        assert_equal(buffer, context.buffer)
      end

      def test_token
        assert_can_find_token("{% rend %}")
        assert_can_find_token("{{ 'foo.js' |  }}")
        assert_can_find_token("<head>\n  ")
        assert_can_find_token("\"></script>\n  ")
        assert_can_find_token("{% rend\n</head>\n")
      end

      private

      def context(line: 0, col: 0, absolute_cursor: nil)
        ctx = CompletionContext.new(storage, file_name, line, col)
        ctx.stubs(absolute_cursor: absolute_cursor) unless absolute_cursor.nil?
        ctx
      end

      def storage
        InMemoryStorage.new(file_name => buffer)
      end

      def file_name
        "layout/theme.liquid"
      end

      def buffer
        <<~LIQUID
          <head>
            {% rend %}
            <script src="{{ 'foo.js' |  }}"></script>
            {% rend
          </head>
        LIQUID
      end

      def assert_can_find_token(token)
        # Being on the first character of a token should try to
        # complete the previous one
        refute_equal(token, context(absolute_cursor: buffer.index(token)).token&.content)

        # Being inside the token should give you the token
        assert_equal(token, context(absolute_cursor: buffer.index(token) + 1).token.content)

        # Being on the next character (outside the token) should give you the previous one.
        assert_equal(token, context(absolute_cursor: buffer.index(token) + token.size).token.content)
      end
    end
  end
end
