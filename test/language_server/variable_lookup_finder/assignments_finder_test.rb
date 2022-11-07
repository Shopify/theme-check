# frozen_string_literal: true

require "test_helper"

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinderTest < Minitest::Test
        def test_find_with_simple_assignments
          finder = AssignmentsFinder.new(<<~LIQUID)
            {%- liquid
              assign target = product
            -%}

            <div class="something">{{ product.available }}</div>

            {%- liquid
              assign foo = cart
            -%}

            {%- liquid
              assign bar = foo
          LIQUID

          finder.find!

          assignments = finder.assignments

          assert_equal(3, assignments.size)
          assert_equal('foo', assignments['bar'].name)
          assert_equal('cart', assignments['foo'].name)
          assert_equal('product', assignments['target'].name)
        end

        def test_find_with_complex_assignments
          finder = AssignmentsFinder.new(<<~LIQUID)
            {%- liquid
              if use_variant
                assign target = product.selected_or_first_available_variant
              else
                assign target = product
              endif
            -%}

            <div class="something">{{ product.available }}</div>

            {%- liquid
              assign foo = cart
            -%}
          LIQUID

          finder.find!

          assignments = finder.assignments

          # TODO: (1/X): https://github.com/shopify/theme-check/issues/n
          # -
          # AssignmentsFinder shouldn't suggest the usage of target, because
          # we can't guess the correct type
          # -
          # assert_equal(1, assignments.size)
          # assert_nil(assignments['target'])
          assert_equal('cart', assignments['foo'].name)
        end
      end
    end
  end
end
