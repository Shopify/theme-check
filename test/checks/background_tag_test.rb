# frozen_string_literal: true
require "test_helper"

class BackgroundTagTest < Minitest::Test
  def test_inline_syntax
    offenses = analyze_theme(
      "templates/index.liquid" => <<~END,
        {% background f = 'lib/commands/accela/access_tokens/create', token_response_body: token_response_body, username: data.username %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_block_syntax
    offenses = analyze_theme(
      "templates/index.liquid" => <<~END,
      {% background source_name: 'my job name', variable: "Hello", delay: 3.5 %}
        Hello {{ variable }}
      {% endbackground %}
      END
    )
    assert_offenses("", offenses)
  end
end
