# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class DeprecateLazysizesTest < Minitest::Test
    def test_valid
      offenses = analyze_theme(
        DeprecateLazysizes.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg" loading="lazy">
        END
      )
      assert_offenses("", offenses)
    end

    def test_reports_lazyload_class
      offenses = analyze_theme(
        DeprecateLazysizes.new,
        "templates/index.liquid" => <<~END,
          <img src="a.jpg" class="lazyload">
          <img src="a.jpg" class="lazyload otherclass">
        END
      )
      assert_offenses(<<~END, offenses)
        Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:1
        Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:2
      END
    end

    def test_reports_data_srcset
      offenses = analyze_theme(
        DeprecateLazysizes.new,
        "templates/index.liquid" => <<~END,
          <img
            alt="Jellyfish"
            sizes="(min-width: 1000px) 930px, 90vw"
            data-srcset="small.jpg 500w,
            medium.jpg 640w,
            big.jpg 1024w"
            data-src="medium.jpg"
            class="lazyload"
          />
        END
      )
      assert_offenses(<<~END, offenses)
        Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:1
        Use the native srcset attribute instead of data-srcset at templates/index.liquid:1
      END
    end

    def test_reports_data_sizes
      offenses = analyze_theme(
        DeprecateLazysizes.new,
        "templates/index.liquid" => <<~END,
          <img
            alt="House by the lake"
            data-sizes="(min-width: 1000px) 930px, 90vw"
            data-srcset="small.jpg 500w,
            medium.jpg 640w,
            big.jpg 1024w"
            data-src="medium.jpg"
            class="lazyload"
          />
        END
      )
      assert_offenses(<<~END, offenses)
        Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:1
        Use the native srcset attribute instead of data-srcset at templates/index.liquid:1
        Use the native sizes attribute instead of data-sizes at templates/index.liquid:1
      END
    end

    def test_reports_sizes_auto
      offenses = analyze_theme(
        DeprecateLazysizes.new,
        "templates/index.liquid" => <<~END,
          <img
            alt="House by the lake"
            data-sizes="auto"
            data-srcset="small.jpg 500w,
            medium.jpg 640w,
            big.jpg 1024w"
            data-src="medium.jpg"
            class="lazyload"
          />
        END
      )
      assert_offenses(<<~END, offenses)
        Use the native loading=\"lazy\" attribute instead of lazysizes at templates/index.liquid:1
        Use the native srcset attribute instead of data-srcset at templates/index.liquid:1
        Use the native sizes attribute instead of data-sizes at templates/index.liquid:1
        Do not set the data-sizes attribute to auto at templates/index.liquid:1
      END
    end
  end
end
