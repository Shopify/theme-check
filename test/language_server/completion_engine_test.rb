# frozen_string_literal: true
require "test_helper"

class CompletionEngineTest < Minitest::Test
  def test_complete_tag
    engine = make_engine(filename => <<~LIQUID)
      {% ren %}
      {% com %}
    LIQUID

    assert_includes(engine.completions(filename, 0, 6), {
      label: "render",
      kind: ThemeCheck::CompletionItemKinds::KEYWORD,
    })
    assert_includes(engine.completions(filename, 1, 6), {
      label: "comment",
      kind: ThemeCheck::CompletionItemKinds::KEYWORD,
    })
  end

  def test_complete_object
    engine = make_engine(filename => <<~LIQUID)
      {{ prod }}
      {{ all_ }}
    LIQUID

    assert_includes(engine.completions(filename, 0, 7), {
      label: "product",
      kind: ThemeCheck::CompletionItemKinds::VARIABLE,
    })
    assert_includes(engine.completions(filename, 1, 7), {
      label: "all_products",
      kind: ThemeCheck::CompletionItemKinds::VARIABLE,
    })
  end

  def test_about_to_type
    engine = make_engine(filename => "{{ }}")
    assert_includes(engine.completions(filename, 0, 3), {
      label: "all_products",
      kind: ThemeCheck::CompletionItemKinds::VARIABLE,
    })

    engine = make_engine(filename => "{% %}")
    assert_includes(engine.completions(filename, 0, 3), {
      label: "render",
      kind: ThemeCheck::CompletionItemKinds::KEYWORD,
    })
  end

  def test_out_of_bounds
    engine = make_engine(filename => "{{ prod }}")
    assert_empty(engine.completions(filename, 0, 8))
    assert_empty(engine.completions(filename, 0, 1))
  end

  def test_find_token
    engine = make_engine(filename => <<~LIQUID)
      <head>
        {% rend %}
        <script src="{{ 'foo.js' |  }}"></script>
      </head>
    LIQUID

    assert_equal("{% rend %}", engine.find_token(filename, 1, 9).content)
    assert_equal("{{ 'foo.js' |  }}", engine.find_token(filename, 2, 29).content)
    assert_equal("<head>\n  ", engine.find_token(filename, 0, 0).content)
    assert_equal("\"></script>\n</head>\n", engine.find_token(filename, 3, 0).content)
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
