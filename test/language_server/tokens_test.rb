# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class TokensTest < Minitest::Test
    def test_tokens
      template = <<~LIQUID
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
      tokens = Tokens.new(template).to_a

      assert_includes(tokens, token(template, "<html>\n  <head>\n    "))
      assert_includes(tokens, token(template, "{% assign foo = 1 %}"))
      assert_includes(tokens, token(template, "{{ 'foo.js' | asset_url | script_tag }}"))
      assert_includes(tokens, token(template, "{% if foo == 1 %}"))
      assert_includes(tokens, token(template, "{% else %}"))
      assert_includes(tokens, token(template, "{% endif %}"))
      assert_includes(tokens, token(template, "{% incomplete\n    "))
      assert_includes(tokens, token(template, "{{ incomplete\n    "))
    end

    private

    def token(string, content)
      Token.new(content, string.index(content), string.index(content) + content.size)
    end
  end
end
