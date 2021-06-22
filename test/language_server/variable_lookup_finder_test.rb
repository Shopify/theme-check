# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class VariableLookupFinderTest < Minitest::Test
      def setup
        super
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_lookup_liquid_variable
        assert_can_lookup_var('', '')
        assert_can_lookup_var(' ', '')
        assert_can_lookup_var("\n\t", '')
        assert_can_lookup_var('}}', '', -2)
        assert_can_lookup_var('cart', 'cart')
        assert_can_lookup_var('cart.', 'cart')
        assert_can_lookup_var('cart.error', 'cart.error')
        assert_can_lookup_var('cart }}', 'cart', -3)
        assert_can_lookup_var('"foo" | replace: ', '')
        assert_can_lookup_var('"foo" | replace: var', 'var')
        assert_can_lookup_var('"foo" | replace: var1, ', '')
        assert_can_lookup_var('"foo" | replace: var1, var2', 'var2')
        assert_can_lookup_var('"foo" | replace: attr: var', 'var')

        # no lookup from out of bounds
        refute_can_lookup_var('}}', -3)
        refute_can_lookup_var('}}', -1)
        refute_can_lookup_var('}}')

        # no lookup when done
        refute_can_lookup_var('cart ')

        # no lookup for filters
        refute_can_lookup_var('cart | ')
        refute_can_lookup_var('cart | image')

        # no lookup for primitives
        refute_can_lookup_var('1')
        refute_can_lookup_var('true')
        refute_can_lookup_var('"foo')
        refute_can_lookup_var('"foo"')

        # square brackets
        assert_can_lookup_var('product["handle', 'product.handle')
        refute_can_lookup_var('product["handle"')
        refute_can_lookup_var('product["handle"]')
        refute_can_lookup_var('product["handle"][')
        assert_can_lookup_var('product["handle"]["', 'product.handle[""]')

        # Can't do this one because the syntax is ambiguous until you
        # finished typing. This could be a positional argument or a
        # named key.
        # refute_can_lookup('{{ cart | image: attr')
      end

      def test_can_lookup_echo_statements
        assert_can_lookup("{% echo \n\t", '')
        assert_can_lookup('{% echo %}', '', -2)
        assert_can_lookup('{% echo cart %}', 'cart', -3)
        assert_can_lookup_tag("echo ", "")
        assert_can_lookup_tag("echo  ", "")
        assert_can_lookup_tag("echo cart", "cart")
        assert_can_lookup_tag("echo cart.", "cart")
        assert_can_lookup_tag("echo cart.error", "cart.error")
        assert_can_lookup_tag('echo "foo" | replace: ', '')
        assert_can_lookup_tag('echo "foo" | replace: var', 'var')
        assert_can_lookup_tag('echo "foo" | replace: var1, ', '')
        assert_can_lookup_tag('echo "foo" | replace: var1, var2', 'var2')
        assert_can_lookup_tag('echo "foo" | replace: attr: ', '')
        assert_can_lookup_tag('echo "foo" | replace: attr: var', 'var')

        # brackets
        assert_can_lookup_tag('echo product["handle', 'product.handle')
        refute_can_lookup_tag('echo product["handle"')
        refute_can_lookup_tag('echo product["handle"]')
        refute_can_lookup_tag('echo product["handle"][')
        assert_can_lookup_tag('echo product["handle"]["', 'product.handle[""]')
      end

      def test_can_lookup_conditional_statements
        ["if", "unless", "elsif"].each do |keyword|
          assert_can_lookup_tag("#{keyword} ", "")
          assert_can_lookup_tag("#{keyword} condition", "condition")
          assert_can_lookup_tag("#{keyword} condition.foo", "condition.foo")
          assert_can_lookup_tag("#{keyword} false or ", "")
          assert_can_lookup_tag("#{keyword} false or condition", "condition")
          assert_can_lookup_tag("#{keyword} conditionA > conditionB", "conditionB")
          assert_can_lookup_tag("#{keyword} foo contains ", "")
          assert_can_lookup_tag("#{keyword} foo contains needle", "needle")
          refute_can_lookup_tag("#{keyword} condition > 10 or")
          refute_can_lookup_tag("#{keyword} condition > 10")
        end
      end

      def test_can_lookup_case_statements
        assert_can_lookup("{% case ", "")
        assert_can_lookup("{% case cart.err", "cart.err")
        assert_can_lookup("{% when ", "")
        assert_can_lookup("{% when cart.err", "cart.err")
        assert_can_lookup(<<~LIQUID, "cart.error", -1)
          {% liquid
            case cart.error
        LIQUID
        assert_can_lookup(<<~LIQUID, "cart.error", -1)
          {% liquid
            case error
            when cart.error
        LIQUID
      end

      def test_can_lookup_cycle_statements
        assert_can_lookup_tag("cycle cart.error", "cart.error")
        assert_can_lookup_tag("cycle '', cart.error", "cart.error")
      end

      def test_can_lookup_for_statements
        assert_can_lookup_tag("for p in ", "")
        assert_can_lookup_tag("for p in cart", "cart")
        assert_can_lookup_tag("for p in cart.error", "cart.error")
        refute_can_lookup_tag("for p in cart.error lim")
        refute_can_lookup_tag("for p in cart.error limit:")
        refute_can_lookup_tag("for p in cart.error limit:2")
        refute_can_lookup_tag("for p in cart.error reversed")
      end

      def test_can_lookup_tablerow_statements
        assert_can_lookup_tag("tablerow p in ", "")
        assert_can_lookup_tag("tablerow p in cart", "cart")
        assert_can_lookup_tag("tablerow p in cart.error", "cart.error")
        refute_can_lookup_tag("tablerow p in cart.error col")
        refute_can_lookup_tag("tablerow p in cart.error col:2")
      end

      def test_can_lookup_render_statements
        assert_can_lookup_tag("render 'snippet', error: ", "")
        assert_can_lookup_tag("render 'snippet', error: cart.error", "cart.error")
        assert_can_lookup_tag("render 'snippet', foo: 'bar', error: ", "")
        assert_can_lookup_tag("render 'snippet', foo: 'bar', error: cart.error", "cart.error")
      end

      def test_can_lookup_assign_statements
        assert_can_lookup_tag("assign foo = ", "")
        assert_can_lookup_tag("assign foo = cart.error", "cart.error")
        assert_can_lookup_tag("assign foo = 'bar' | replace: ", "")
        assert_can_lookup_tag("assign foo = 'bar' | replace: from", "from")
        assert_can_lookup_tag("assign foo = 'bar' | replace: 'from', ", "")
        assert_can_lookup_tag("assign foo = 'bar' | replace: 'from', to", "to")
        assert_can_lookup_tag("assign foo = 'bar' | replace: attr: ", "")
        assert_can_lookup_tag("assign foo = 'bar' | replace: attr: var", "var")
      end

      def test_can_lookup_inside_multiline_liquid_tags
        assert_can_lookup(<<~LIQUID, '', -1)
          {% liquid
            assign foo = cart
            assign bar =\t
        LIQUID

        assert_can_lookup(<<~LIQUID, 'cart', -1)
          {% liquid
            assign foo = blob
            assign bar = cart
        LIQUID
      end

      def assert_can_lookup_var(variable_content, expected_markup, offset = 0)
        assert_can_lookup("{{ #{variable_content}", expected_markup, offset)
        assert_can_lookup("{{- #{variable_content}", expected_markup, offset)
      end

      def refute_can_lookup_var(variable_content, offset = 0)
        refute_can_lookup("{{ #{variable_content}", offset)
        refute_can_lookup("{{- #{variable_content}", offset)
      end

      def assert_can_lookup_tag(tag_content, expected_markup)
        assert_can_lookup("{% #{tag_content}", expected_markup)
        assert_can_lookup("{%- #{tag_content}", expected_markup)
        assert_can_lookup(<<~LIQUID, expected_markup, -1)
          {% liquid
            #{tag_content}
        LIQUID
        assert_can_lookup(<<~LIQUID, expected_markup, -1)
          {%- liquid
            #{tag_content}
        LIQUID
      end

      def assert_can_lookup(token, expected_markup, offset = 0)
        # Make sure nothing blows up by doing lookups at every point
        # in every test strings.
        (0...token.size).each do |i|
          assert(VariableLookupFinder.lookup(token, i) || true)
        end if ENV["PARANOID"]

        assert_equal(
          Liquid::VariableLookup.parse(expected_markup),
          VariableLookupFinder.lookup(token, token.size + offset),
          <<~ERRMSG,
            Expected to find a variable lookup for '#{expected_markup}' in the following content:
            #{token}
          ERRMSG
        )
      end

      def refute_can_lookup_tag(tag_content)
        refute_can_lookup("{% #{tag_content}")
        refute_can_lookup(<<~LIQUID, -1)
          {% liquid
            #{tag_content}
        LIQUID
      end

      def refute_can_lookup(token, offset = 0)
        # Make sure nothing blows up by doing lookups at every point
        # in every test strings.
        (0...token.size).each do |i|
          assert(VariableLookupFinder.lookup(token, i) || true)
        end if ENV["PARANOID"]

        assert_nil(
          VariableLookupFinder.lookup(token, token.size + offset),
          <<~ERRMSG,
            Expected lookup to be nil at the specified cursor position:
            #{token}
            #{' ' * (token.size + offset)}^
          ERRMSG
        )
      end
    end
  end
end
