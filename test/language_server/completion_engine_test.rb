# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class CompletionEngineTest < Minitest::Test
      def setup
        super
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_complete_tag
        engine = make_engine(filename => <<~LIQUID)
          {% ren %}
          {% com %}
        LIQUID

        assert_includes(engine.completions(filename, 0, 6), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
        assert_includes(engine.completions(filename, 1, 6), {
          label: "comment",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_cursor_on_tag?
        engine = make_engine(filename => <<~LIQUID)
          {% ren %}
          {% com %}
        LIQUID

        assert_includes(engine.completions(filename, 0, 6), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
        assert_includes(engine.completions(filename, 1, 6), {
          label: "comment",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_complete_object
        engine = make_engine(filename => <<~LIQUID)
          {{ prod }}
          {{ all_ }}
        LIQUID

        assert_includes(engine.completions(filename, 0, 7), {
          label: "product",
          kind: CompletionItemKinds::VARIABLE,
        })
        assert_includes(engine.completions(filename, 1, 7), {
          label: "all_products",
          kind: CompletionItemKinds::VARIABLE,
        })
      end

      def test_about_to_type
        engine = make_engine(filename => "{{ }}")
        assert_includes(engine.completions(filename, 0, 3), {
          label: "all_products",
          kind: CompletionItemKinds::VARIABLE,
        })

        engine = make_engine(filename => "{% %}")
        assert_includes(engine.completions(filename, 0, 3), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_out_of_bounds
        engine = make_engine(filename => "{{ prod }}")
        assert_empty(engine.completions(filename, 0, 8))
        assert_empty(engine.completions(filename, 0, 1))
      end

      def test_find_token
        content = <<~LIQUID
          <head>
            {% rend %}
            <script src="{{ 'foo.js' |  }}"></script>
            {% rend
          </head>
        LIQUID
        engine = make_engine(filename => content)

        assert_can_find_token(engine, content, "{% rend %}")
        assert_can_find_token(engine, content, "{{ 'foo.js' |  }}")
        assert_can_find_token(engine, content, "<head>\n  ")
        assert_can_find_token(engine, content, "\"></script>\n  ")
        assert_can_find_token(engine, content, "{% rend\n</head>\n")
      end

      private

      def make_engine(files)
        storage = InMemoryStorage.new(files)
        CompletionEngine.new(storage)
      end

      def filename
        "layout/theme.liquid"
      end

      def assert_can_find_token(engine, content, token)
        # Being on the first character of a token should try to
        # complete the previous one
        refute_equal(token, engine.find_token(content, content.index(token))&.content)

        # Being inside the token should give you the token
        assert_equal(token, engine.find_token(content, content.index(token) + 1).content)

        # Being on the next character (outside the token) should give you the previous one.
        assert_equal(token, engine.find_token(content, content.index(token) + token.size).content)
      end
    end
  end
end
