# frozen_string_literal: true
require "test_helper"

class DeprecateBgsizesTest < Minitest::Test
  def test_valid
    offenses = analyze_theme(
      ThemeCheck::DeprecateBgsizes.new,
      "templates/index.liquid" => <<~END,
        <div class="other-class"></div>
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_data_bgset
    offenses = analyze_theme(
      ThemeCheck::DeprecateBgsizes.new,
      "templates/index.liquid" => <<~END,
        <div class="lazyload" data-bgset="image-200.jpg [--small] | image-300.jpg [--medium] | image-400.jpg"></div>
      END
    )
    assert_offenses(<<~END, offenses)
      Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:1
      Use the CSS imageset attribute instead of data-bgset at templates/index.liquid:1
    END
  end
end
