# frozen_string_literal: true
require "test_helper"

class ValidHTMLTranslationTest < Minitest::Test
  def test_do_not_report_valid_html
    offenses = analyze_theme(
      ThemeCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: "<h1>Hello, world</h1>",
        image_html: "<img src='spongebob.png'>",
        line_break_html: "<br>",
        self_closing_svg_html: "<svg />"
      ),
    )
    assert_offenses("", offenses)
  end

  def test_report_invalid_html
    offenses = analyze_theme(
      ThemeCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: "<h1>Hello, world"
      ),
    )
    assert_offenses(<<~END, offenses)
      'hello_html' contains invalid HTML:
      1:17: ERROR: Premature end of file  Currently open tags: html, h1.
      <h1>Hello, world
                      ^
    END
  end

  def test_report_nested_invalid_html
    offenses = analyze_theme(
      ThemeCheck::ValidHTMLTranslation.new,
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
    assert_offenses(<<~END, offenses)
      'hello.world.today.good.day_html' contains invalid HTML:
      1:17: ERROR: Premature end of file  Currently open tags: html, h1.
      <h1>Hello, world
                      ^
    END
  end

  def test_report_pluralized_key
    offenses = analyze_theme(
      ThemeCheck::ValidHTMLTranslation.new,
      "locales/en.default.json" => JSON.dump(
        hello_html: { one: "<h1>Hello, world" }
      ),
    )
    assert_offenses(<<~END, offenses)
      'hello_html.one' contains invalid HTML:
      1:17: ERROR: Premature end of file  Currently open tags: html, h1.
      <h1>Hello, world
                      ^
    END
  end
end
