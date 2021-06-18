# frozen_string_literal: true
require "test_helper"

class HtmlParsingErrorTest < Minitest::Test
  def test_valid
    offenses = analyze_theme(
      ThemeCheck::HtmlParsingError.new,
      "templates/index.liquid" => <<~END,
        <img src="muffin.jpeg" atl="Muffin">
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_to_many_attributes
    offenses = analyze_theme(
      ThemeCheck::HtmlParsingError.new,
      "templates/index.liquid" => <<~END,
        <img src="muffin.jpeg" #{(1..400).map { |i| "attribute#{i}" }.join(" ")}>
      END
    )
    assert_offenses(<<~END, offenses)
      HTML in this template can not be parsed: Attributes per element limit exceeded at templates/index.liquid
    END
  end
end
