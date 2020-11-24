require "test_helper"

class UnusedSnippetsTest < Minitest::Test
  def test_finds_unused
    offenses = analyze_theme(
      ThemeCheck::UnusedSnippets,
      "templates/index.liquid" => <<~END,
        {% include 'muffin' %}
      END
      "snippets/muffin.liquid" => <<~END,
        Here's a muffin
      END
      "snippets/unused.liquid" => <<~END,
        This is not used
      END
    )
    assert_equal(<<~END.chomp, offenses.join)
      This template is not used at snippets/unused.liquid
    END
  end

  def test_ignores_dynamic_includes
    offenses = analyze_theme(
      ThemeCheck::UnusedSnippets,
      "templates/index.liquid" => <<~END,
        {% assign name = 'muffin' %}
        {% include name %}
      END
      "snippets/muffin.liquid" => <<~END,
        Here's a muffin
      END
      "snippets/unused.liquid" => <<~END,
        This is not used
      END
    )
    assert_equal("", offenses.join)
  end
end
