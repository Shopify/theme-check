# frozen_string_literal: true
require "test_helper"

class CompletionEngineTest < Minitest::Test
  def test_complete_tag
    engine = make_engine(filename => <<~LIQUID)
      {% ren %}
      {% com %}
    LIQUID

    assert_includes(engine.completions(filename, 1, 6), {
      label: "render",
      kind: ThemeCheck::CompletionItemKinds::KEYWORD,
    })
    assert_includes(engine.completions(filename, 2, 6), {
      label: "comment",
      kind: ThemeCheck::CompletionItemKinds::KEYWORD,
    })
  end

  def test_find_token
    engine = make_engine(filename => <<~LIQUID)
      <head>
        {% rend %}
        <script src="{{ 'foo.js' |  }}"></script>
      </head>
    LIQUID

    assert_equal("{% rend %}", engine.find_token(filename, 2, 10).content)
    assert_equal("{{ 'foo.js' |  }}", engine.find_token(filename, 3, 30).content)
    assert_equal("<head>\n  ", engine.find_token(filename, 1, 1).content)
    assert_equal("\"></script>\n</head>\n", engine.find_token(filename, 4, 1).content)
  end

  private

  def make_engine(files)
    storage = ThemeCheck::InMemoryStorage.new(files)
    ThemeCheck::CompletionEngine.new(storage)
  end

  def filename
    "layout/theme.liquid"
  end
end
