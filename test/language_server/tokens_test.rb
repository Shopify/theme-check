# frozen_string_literal: true
require "test_helper"

module ThemeCheck
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
            <div {% if thing > 0 %}id=1{% endif %}>
            <div {% if thing < 0 %}id=1{% endif %}>
            {% unless a <marquee>
          </body>
        </html>
      LIQUID
      tokens = Tokens.new(contents).to_a

      assert_includes(tokens, token(contents, "<html>", 'html'))
      assert_includes(tokens, token(contents, "<head>", 'head'))
      assert_includes(tokens, token(contents, "{% assign foo = 1 %}"))
      assert_includes(tokens, token(contents, "<script src=\"", 'script'))
      assert_includes(tokens, token(contents, "{{ 'foo.js' | asset_url }}", 'script'))
      assert_includes(tokens, token(contents, "\" async>", 'script'))
      assert_includes(tokens, token(contents, "{% if foo == 1 %}"))
      assert_includes(tokens, token(contents, "{% else %}"))
      assert_includes(tokens, token(contents, "{% endif %}"))
      assert_includes(tokens, token(contents, "{% incomplete\n    "))
      assert_includes(tokens, token(contents, "{{ incomplete\n    "))
      assert_includes(tokens, token(contents, "<div ", 'div'))
      assert_includes(tokens, token(contents, "{% if thing > 0 %}", 'div'))
      assert_includes(tokens, token(contents, "id=1", 'div'))
      assert_includes(tokens, token(contents, "{% if thing < 0 %}", 'div'))
      assert_includes(tokens, token(contents, "{% unless a "))
      assert_includes(tokens, token(contents, "<marquee>", 'marquee'))
      assert_includes(tokens, token(contents, "</body>"))
      assert_includes(tokens, token(contents, "</html>"))
    end

    private

    def token(string, content, tag_name = nil)
      Token.new(content, string.index(content), string.index(content) + content.size, tag_name)
    end
  end
end
