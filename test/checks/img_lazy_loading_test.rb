# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class ImgLazyLoadingTest < Minitest::Test
    def test_no_offense_with_loading_lazy_attribute
      offenses = analyze_theme(
        ImgLazyLoading.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg" loading="lazy">
          <img src="a.jpg" loading="LAZY">
          <img src="a.jpg" LOADING="LAZY">
        END
      )
      assert_offenses("", offenses)
    end

    def test_reports_missing_loading_lazy_attribute
      offenses = analyze_theme(
        ImgLazyLoading.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg">
        END
      )
      assert_offenses(<<~END, offenses)
        Add loading="lazy" to defer loading of images at templates/index.liquid:1
      END
    end
  end
end
