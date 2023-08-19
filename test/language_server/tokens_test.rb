# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class TokensTest < Minitest::Test
    def test_tokens
      contents = <<~LIQUID
        <html>
          <head>
            {% assign foo = 1 %}
            {{ 'foo.js' | asset_url | script_tag }}
            <script src="{{ 'foo.js' | asset_url }}" async></script>
            {% if true %}content{% endif %}
          </head>
          <body>
            {% if foo == 1 %}
              <div>Hello World</div>
            {% else %}
              <div>Bye World</div>
            {% endif %}
            {% incomplete
            {{ incomplete
            {% render %}
          </body>
        </html>
      LIQUID
      tokens = Tokens.new(contents).to_a

      assert_includes(tokens, token(contents, "<html>\n  <head>\n    "))
      assert_includes(tokens, token(contents, "{% assign foo = 1 %}"))
      assert_includes(tokens, token(contents, "{{ 'foo.js' | asset_url | script_tag }}"))
      assert_includes(tokens, token(contents, "{% if foo == 1 %}"))
      assert_includes(tokens, token(contents, "{% else %}"))
      assert_includes(tokens, token(contents, "{% endif %}"))
      assert_includes(tokens, token(contents, "{% incomplete\n    "))
      assert_includes(tokens, token(contents, "{{ incomplete\n    "))
    end

    private

    def token(string, content)
      Token.new(content, string.index(content), string.index(content) + content.size)
    end
  end
end
