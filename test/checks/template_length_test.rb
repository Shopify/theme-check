# frozen_string_literal: true
require "test_helper"

class TemplateLengthTest < Minitest::Test
  def test_finds_unused
    offenses = analyze_theme(
      ThemeCheck::TemplateLength.new(max_length: 10),
      "templates/long.liquid" => <<~END,
        #{"\n" * 10}
      END
      "templates/short.liquid" => <<~END,
        #{"\n" * 9}
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      Template has too many lines [11/10] at templates/long.liquid
    END
  end
end
