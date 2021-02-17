# frozen_string_literal: true
require "test_helper"

class TokensTest < Minitest::Test
  def test_tokens
    tokens = ThemeCheck::Tokens.new(<<~LIQUID).to_a
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
          {% render 'foo.js' %}
        </body>
      </html>
    LIQUID

    assert_includes(tokens, ThemeCheck::Token.new("<html>\n  <head>\n    ", 0, 0, 2, 3))
    assert_includes(tokens, ThemeCheck::Token.new("{{ 'foo.js' | asset_url | script_tag }}", 3, 4, 3, 42))
    assert_includes(tokens, ThemeCheck::Token.new("{{ 'foo.js' | asset_url }}", 4, 17, 4, 42))
  end

  def test_tokens_on_same_line
    tokens = ThemeCheck::Tokens.new('<div>{% if true %}content{% endif %}</div>').to_a

    assert_includes(tokens, ThemeCheck::Token.new("{% if true %}", 0, 5, 0, 17))
    assert_includes(tokens, ThemeCheck::Token.new("{% endif %}", 0, 25, 0, 35))
  end
end
