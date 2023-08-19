# frozen_string_literal: true
require "test_helper"

class ValidHTMLTranslationTest < Minitest::Test
  def test_do_not_report_valid_html
    offenses = analyze_theme(
      PlatformosCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: "<h1>Hello, world</h1>",
        image_html: "<img src='spongebob.png'>",
        line_break_html: "<br>",
        self_closing_svg_html: "<svg />",
        foo: "bar",
      ),
    )
    assert_offenses("", offenses)
  end

  def test_report_invalid_html
    offenses = analyze_theme(
      PlatformosCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: "<h1>Hello, world"
      ),
    )

    # Here we're using assert_includes because nokogiri doesn't report
    # the error the same way on windows. So unit tests on the error message
    # break.
    assert_includes(offenses.join("\n"), <<~END)
      'hello_html' contains invalid HTML:
    END
  end

  def test_report_nested_invalid_html
    offenses = analyze_theme(
      PlatformosCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello: {
          world: {
            today: {
              good: {
                day_html: "<h1>Hello, world",
              },
            },
          },
        },
      ),
    )
    assert_includes(offenses.join("\n"), <<~END)
      'hello.world.today.good.day_html' contains invalid HTML:
    END
  end

  def test_report_pluralized_key
    offenses = analyze_theme(
      PlatformosCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: { one: "<h1>Hello, world" }
      ),
    )
    assert_includes(offenses.join("\n"), <<~END)
      'hello_html.one' contains invalid HTML:
    END
  end
end
