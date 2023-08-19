# frozen_string_literal: true
require "test_helper"

class ValidJsonTest < Minitest::Test
  def test_detects_json_error
    offenses = analyze_theme(
      PlatformosCheck::ValidJson.new,
      "locales/en.json" => "{",
    )
    assert_offenses(<<~END, offenses)
      Invalid syntax in JSON at locales/en.json
    END
  end

  def test_valid_json
    offenses = analyze_theme(
      PlatformosCheck::ValidJson.new,
      "locales/en.json" => "{}",
    )
    assert_offenses("", offenses)
  end
end
