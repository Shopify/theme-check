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

    assert_includes(tokens, ThemeCheck::Token.new("<html>\n  <head>\n    ", 1, 1, 3, 4))
    assert_includes(tokens, ThemeCheck::Token.new("{{ 'foo.js' | asset_url | script_tag }}", 4, 5, 4, 43))
    assert_includes(tokens, ThemeCheck::Token.new("{{ 'foo.js' | asset_url }}", 5, 18, 5, 43))
  end

  def test_tokens_on_same_line
    tokens = ThemeCheck::Tokens.new('<div>{% if true %}content{% endif %}</div>').to_a

    assert_includes(tokens, ThemeCheck::Token.new("{% if true %}", 1, 6, 1, 18))
    assert_includes(tokens, ThemeCheck::Token.new("{% endif %}", 1, 26, 1, 36))
  end
end
