# frozen_string_literal: true

require "test_helper"

module PlatformosCheck
  module LanguageServer
    module VariableLookupFinder
      class LiquidFixerTest < Minitest::Test
        def test_single_quotes
          assert_parsable("{{ 'aaaa' }}", "{{ 'aaaa")
        end

        def test_double_quotes
          assert_parsable('{{ "aaaa" }}', '{{ "aaaa')
        end

        def test_square_brackets
          assert_parsable('{{ product[] }}', '{{ product[')
        end

        def test_cycle_statements
          assert_can_parse('cycle cart.error')
          assert_can_parse('cycle "", cart.error')
        end

        def test_render
          assert_can_parse('render "snippet", error:')
          assert_can_parse('render "snippet", error: cart.error')
          assert_can_parse('render "snippet", foo: "bar", error:')
          assert_can_parse('render "snippet", foo: "bar", error: cart.error')
        end

        def test_echo_statements
          assert_can_parse('echo')
          assert_can_parse('echo cart')
          assert_can_parse('echo cart.')
          assert_can_parse('echo cart.error')
          assert_can_parse('echo "foo" | replace: attr:')
          assert_can_parse('echo "foo" | replace: var1, var2')
          assert_can_parse('echo product["handle"]', 'echo product["handle')
          assert_can_parse('echo product["handle"][""]', 'echo product["handle"]["')
        end

        def test_assign
          assert_can_parse("assign foo =")
          assert_can_parse("assign foo = cart.error")
          assert_can_parse("assign foo = 'bar' | replace:")
          assert_can_parse("assign foo = 'bar' | replace: from")
          assert_can_parse("assign foo = 'bar' | replace: 'from',")
          assert_can_parse("assign foo = 'bar' | replace: 'from', to")
          assert_can_parse("assign foo = 'bar' | replace: attr:")
          assert_can_parse("assign foo = 'bar' | replace: attr: var")
        end

        def test_multiline_assigns
          assert_parsable("{% assign foo = cart\nassign bar = %}", "{% assign foo = cart\nassign bar =")
          assert_parsable("{%- assign foo = cart\nassign bar = %}", "{%- assign foo = cart\nassign bar =")

          assert_parsable("{% assign bar = %}", "{% liquid\nassign foo = cart\nassign bar =")
          assert_parsable("{% assign bar = %}", "{%- liquid\nassign foo = cart\nassign bar =")
        end

        def test_if_statements
          [
            'condition > 10',
            'condition',
            'conditionA > conditionB',
            'false or condition',
            'foo contains needle',
            'product.available',
          ].each do |condition|
            assert_parsable("{% if #{condition} %}{% endif %}", "{% if #{condition}")
            assert_parsable("{%- if #{condition} %}{% endif %}", "{%- if #{condition}")

            assert_parsable("{% if #{condition} %}{% endif %}", "{% liquid\n if #{condition}")
            assert_parsable("{% if #{condition} %}{% endif %}", "{%- liquid\n if #{condition}")
          end
        end

        def test_invalid_if_statements
          [
            'if',
            'if false or',
            'if foo contains',
          ].each { |statement| refute_parsable(statement) }
        end

        def test_unless_statements
          [
            'condition > 10',
            'condition',
            'conditionA > conditionB',
            'false or condition',
            'foo contains needle',
            'product.available',
          ].each do |condition|
            assert_parsable("{% unless #{condition} %}{% endunless %}", "{% unless #{condition}")
            assert_parsable("{%- unless #{condition} %}{% endunless %}", "{%- unless #{condition}")

            assert_parsable("{% unless #{condition} %}{% endunless %}", "{% liquid\n unless #{condition}")
            assert_parsable("{% unless #{condition} %}{% endunless %}", "{%- liquid\n unless #{condition}")
          end
        end

        def test_invalid_unless_statements
          [
            'unless',
            'unless false or',
            'unless foo contains',
          ].each { |statement| refute_parsable(statement) }
        end

        def test_elsif_statements
          [
            'condition > 10',
            'condition',
            'conditionA > conditionB',
            'false or condition',
            'foo contains needle',
            'product.available',
          ].each do |condition|
            assert_parsable("{% if x %}{% elsif #{condition} %}{% endif %}", "{% elsif #{condition}")
            assert_parsable("{% if x %}{%- elsif #{condition} %}{% endif %}", "{%- elsif #{condition}")

            assert_parsable("{% if x %}{% elsif #{condition} %}{% endif %}", "{% liquid\n elsif #{condition}")
            assert_parsable("{% if x %}{% elsif #{condition} %}{% endif %}", "{%- liquid\n elsif #{condition}")
          end
        end

        def test_invalid_elsif_statements
          [
            'elsif',
            'elsif false or',
            'elsif foo contains',
          ].each { |statement| refute_parsable(statement) }
        end

        def test_case_statements
          assert_parsable("{% case cart.error %}{% endcase %}", "{% case cart.error")
          assert_parsable("{%- case cart.error %}{% endcase %}", "{%- case cart.error")

          assert_parsable("{% case cart.error %}{% endcase %}", "{% liquid\n case cart.error")
          assert_parsable("{% case cart.error %}{% endcase %}", "{%- liquid\n case cart.error")
        end

        def test_when_statements
          assert_parsable("{% case x %}{% when cart.error %}{% endcase %}", "{% when cart.error")
          assert_parsable("{% case x %}{%- when cart.error %}{% endcase %}", "{%- when cart.error")

          assert_parsable("{% case x %}{% when cart.error %}{% endcase %}", "{% liquid\n when cart.error")
          assert_parsable("{% case x %}{% when cart.error %}{% endcase %}", "{%- liquid\n when cart.error")
        end

        def test_invalid_case_when_statements
          ['case', 'when'].each { |statement| refute_parsable(statement) }
        end

        def test_for_statements
          [
            'cart',
            'cart.error',
          ].each do |range|
            assert_parsable("{% for p in #{range} %}{% endfor %}", "{% for p in #{range}")
            assert_parsable("{%- for p in #{range} %}{% endfor %}", "{%- for p in #{range}")

            assert_parsable("{% for p in #{range} %}{% endfor %}", "{% liquid\n for p in #{range}")
            assert_parsable("{% for p in #{range} %}{% endfor %}", "{%- liquid\n for p in #{range}")
          end
        end

        def test_invalid_for_statements
          [
            'for p in',
            'for if',
          ].each do |statement|
            refute_parsable(statement)
          end
        end

        def test_tablerow_statements
          [
            'cart',
            'cart.error',
          ].each do |range|
            assert_parsable("{% tablerow p in #{range} %}{% endtablerow %}", "{% tablerow p in #{range}")
            assert_parsable("{%- tablerow p in #{range} %}{% endtablerow %}", "{%- tablerow p in #{range}")

            assert_parsable("{% tablerow p in #{range} %}{% endtablerow %}", "{% liquid\n tablerow p in #{range}")
            assert_parsable("{% tablerow p in #{range} %}{% endtablerow %}", "{%- liquid\n tablerow p in #{range}")
          end
        end

        def test_invalid_tablerow_statements
          ['tablerow p in'].each { |statement| refute_parsable(statement) }
        end

        private

        def assert_can_parse(expected, content = nil)
          content ||= expected

          assert_parsable("{% #{expected} %}", "{% #{content}")
          assert_parsable("{%- #{expected} %}", "{%- #{content}")

          assert_parsable("{% #{expected} %}", "{% liquid\n#{content}")
          assert_parsable("{% #{expected} %}", "{%- liquid\n#{content}")
        end

        def assert_parsable(expected, content)
          actual = LiquidFixer.new(content, content.size).parsable
          parse_error = ''

          begin
            Liquid::Template.parse(actual)
          rescue Liquid::SyntaxError => error
            parse_error = <<~MESSAGE

              ------------------------------------------------------------------
              Syntax error: #{error.message}
              Test case: #{name}
              ------------------------------------------------------------------
            MESSAGE
          end

          assert_equal(expected, actual, parse_error)
        end

        def refute_parsable(content)
          [
            "{% #{content} ",
            "{%- #{content} ",
            "{% liquid\n#{content} ",
            "{%- liquid\n#{content} ",
          ].each do |liquid_content|
            assert_parsable('', liquid_content)
          end
        end
      end
    end
  end
end
