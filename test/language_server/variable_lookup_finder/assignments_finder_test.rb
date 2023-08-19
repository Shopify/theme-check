# frozen_string_literal: true

require "test_helper"

module PlatformosCheck
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
              assign bar = foo█
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

          assert_equal(1, assignments.size)
          assert_nil(assignments['target'])
          assert_equal('cart', assignments['foo'].name)
        end

        def test_assignments_finder_single_line_assignments
          assert_assignments_finder("{% assign target = cart %}", 'target' => 'cart')
          assert_assignments_finder("{% assign target = cart█", 'target' => 'cart')
        end

        def test_assignments_finder_with_multi_line_assignments
          template1 = <<~LIQUID
            {%- liquid
              assign target = cart
            -%}
          LIQUID

          template2 = <<~LIQUID
            {%- liquid
              assign target = cart█
          LIQUID

          assert_assignments_finder(template1, 'target' => 'cart')
          assert_assignments_finder(template2, 'target' => 'cart')
        end

        def test_assignments_finder_with_if_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              if use_variant
                assign var2 = var1
                assign var3 = var2█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'var1',
            'var3' => 'var2',
          })
        end

        def test_assignments_finder_with_if_and_else_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              if use_variant
                assign var2 = var1
                assign var3 = var2
              else
                assign var4 = var1
                assign var5 = var4█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'var1',
            'var5' => 'var4',
          })
        end

        def test_assignments_finder_with_if_and_elsif_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              if use_variant
                assign var2 = var1
                assign var3 = var2
              elsif something
                assign var4 = var1
                assign var5 = var4█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'var1',
            'var5' => 'var4',
          })
        end

        def test_assignments_finder_with_if_statements_when_local_scope_must_not_be_considered
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              if use_variant
                assign var2 = var1
                assign var3 = var2
              elsif something
                assign var4 = var1
                assign var5 = var4
              else
                assign var6 = var5
                assign var7 = var6
              endif

              assign var8 = cart█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var8' => 'cart',
          })
        end

        def test_assignments_finder_with_unless_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              unless use_variant
                assign var2 = var1
                assign var3 = var2█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'var1',
            'var3' => 'var2',
          })
        end

        def test_assignments_finder_with_unless_and_else_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              unless use_variant
                assign var2 = var1
                assign var3 = var2
              else
                assign var4 = var1
                assign var5 = var4█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'var1',
            'var5' => 'var4',
          })
        end

        def test_assignments_finder_with_unless_statements_when_local_scope_must_not_be_considered
          template = <<~LIQUID
            {%- liquid
              assign var1 = product

              unless use_variant
                assign var2 = var1
                assign var3 = var2
              elsif something
                assign var4 = var1
                assign var5 = var4
              else
                assign var6 = var5
                assign var7 = var6
              endunless

              assign var8 = cart█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var8' => 'cart',
          })
        end

        def test_assignments_finder_with_for_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {%- for var2 in collections.first.products -%}
              {% assign var3 = var2 %}
              {{ var3.title }}█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'collections',
            'var3' => 'var2',
          })
        end

        def test_assignments_finder_with_for_statements_and_ranges
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {%- for var2 in (1..4) -%}
              {% echo█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'number',
          })
        end

        def test_assignments_finder_with_for_statements_and_variable_based_ranges
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {% assign var2 = 1 %}
            {% assign var3 = 4 %}
            {%- for var4 in (var2..var3) -%}
              {% echo█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'number',
            'var3' => 'number',
            'var4' => 'var2',
          })
        end

        def test_assignments_finder_with_for_statements_and_variable_and_literal_ranges
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {% assign var2 = 1 %}
            {%- for var3 in (1..var2) -%}
              {% echo█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'number',
            'var3' => 'number',
          })
        end

        def test_assignments_finder_with_form_tag
          template = <<~LIQUID
            {%- form 'localization', id: 'FooterLanguageFormNoScript', class: 'localization-form' -%}
              {%- for language in localization.available_languages -%}
                <option value="{{ language.█
          LIQUID

          assert_assignments_finder(template, {
            'language' => 'localization',
          })
        end

        def test_assignments_finder_with_paginate_tag
          template = <<~LIQUID
            {% paginate collection.products by 5 %}
              {% for var1 in collection.products -%}
                {% echo █
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'collection',
          })
        end

        def test_assignments_finder_with_style_tag
          template = <<~LIQUID
            {% style %}
              .h1 {
                  {%- for language in localization.available_languages -%}
                    <option value="{{ language.█
          LIQUID

          assert_assignments_finder(template, {
            'language' => 'localization',
          })
        end

        def test_assignments_finder_with_stylesheet_tag
          template = <<~LIQUID
            {% stylesheet %}
              .h1 {
                  {%- for language in localization.available_languages -%}
                    <option value="{{ language.█
          LIQUID

          assert_assignments_finder(template, {
            'language' => 'localization',
          })
        end

        def test_assignments_finder_with_for_and_else_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {% for var2 in collections.first.products %}
              {% assign var3 = var2 %}
              {{ var3.title }}
            {% else %}
              {% assign var4 = var1 %}
              {% assign var5 = var4█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'var1',
            'var5' => 'var4',
          })
        end

        def test_assignments_finder_with_for_statements_when_local_scope_must_not_be_considered
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {%- for var2 in collections.first.products -%}
              {% assign var3 = var2 %}
              {{ var3.title }}
            {%- else -%}
              {% assign var4 = var2 %}
              There are no products in this collection.
            {%- endfor -%}
            {%- liquid
              assign var5 = cart█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var5' => 'cart',
          })
        end

        def test_assignments_finder_with_table_row_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            <table>
              {% tablerow var2 in collections.first.products %}
                {% assign var3 = var2 %}
                {{ var3.title█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'collections',
            'var3' => 'var2',
          })
        end

        def test_assignments_finder_with_table_row_statements_when_local_scope_must_not_be_considered
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            <table>
              {% tablerow var2 in collections.first.products %}
                {% assign var3 = var2 %}
                {{ var3.title }}
              {% endtablerow %}
            </table>
            {%- liquid
              assign var4 = cart█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'cart',
          })
        end

        def test_assignments_finder_with_case_statements
          template = <<~LIQUID
            {% assign var1 = product %}

            {% case var1.type %}
              {% when "type1" %}
                {% assign var2 = var1 %}
                {% assign var3 = var2█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var2' => 'var1',
            'var3' => 'var2',
          })
        end

        def test_assignments_finder_with_case_and_when_statements
          template = <<~LIQUID
            {% assign var1 = product %}

            {% case var1.type %}
              {% when "type1" %}
                {% assign var2 = var1 %}
                {% assign var3 = var2 %}
              {% when "type2", "type3" %}
                {% assign var4 = var1 %}
                {% assign var5 = var4█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var4' => 'var1',
            'var5' => 'var4',
          })
        end

        def test_assignments_finder_with_case_and_else_statements
          template = <<~LIQUID
            {% assign var1 = product %}

            {% case var1.type %}
              {% when "type1" %}
                {% assign var2 = var1 %}
                {% assign var3 = var2 %}
              {% when "type2", "type3" %}
                {% assign var4 = var1 %}
                {% assign var5 = var4 %}
              {% else %}
                {% assign var6 = var1 %}
                {% assign var7 = var6█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var6' => 'var1',
            'var7' => 'var6',
          })
        end

        def test_assignments_finder_with_case_statements_when_local_scope_must_not_be_considered
          template = <<~LIQUID
            {% assign var1 = product %}

            {% case var1.type %}
              {% when "type1" %}
                {% assign var2 = var1 %}
                {% assign var3 = var2 %}
              {% when "type2", "type3" %}
                {% assign var4 = var1 %}
                {% assign var5 = var4 %}
              {% else %}
                {% assign var6 = var1 %}
                {% assign var7 = var6 %}
            {% endcase %}

            {% assign var8 = cart█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var8' => 'cart',
          })
        end

        def test_assignments_finder_with_colisions_between_variables_and_if_statements
          template = <<~LIQUID
            {%- liquid
              assign var1 = color
              assign var2 = article

              if use_variant
                assign var1 = product
              else
                assign var1 = cart
              endif
            -%}
          LIQUID

          assert_assignments_finder(template, {
            'var2' => 'article',
          })
        end

        def test_assignments_finder_with_colisions_between_if_statements_and_variables
          template = <<~LIQUID
            {%- liquid
              if use_variant
                assign var1 = product
              else
                assign var1 = cart
              endif
              assign var1 = color
              assign var2 = article
            -%}
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'color',
            'var2' => 'article',
          })
        end

        def test_assignments_finder_with_nested_scopes
          template = <<~LIQUID
            {%- liquid
              assign var1 = product
            -%}
            {% if var1.something %}
              {% assign var2 = var1 %}

              {% if var2.something %}
                {% assign var3 = var2 %}

                {% if var3.something %}
                  {% assign var4 = var3 %}
                  {% assign var2 = var4 %}
                {% endif %}

                {% assign var5 = var3 %}█
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'product',
            'var3' => 'var2',
            'var5' => 'var3',
          })
        end

        def test_assignments_finder_with_literal_types
          template = <<~LIQUID
            {%- liquid
              assign var1 = 'something'
              assign var2 = 2
              assign var3 = 2.0
              assign var4 = true
              assign var5 = nil
            -%}
          LIQUID

          assert_assignments_finder(template, {
            'var1' => 'string',
            'var2' => 'number',
            'var3' => 'number',
            'var4' => 'boolean',
            'var5' => 'nil',
          })
        end

        private

        def assert_assignments_finder(template, expected_assignments)
          template = template.split('█').first

          finder = AssignmentsFinder.new(template)
          finder.find!

          actual_assignments = finder.assignments

          assert_equal(
            expected_assignments.size,
            actual_assignments.size,
            debug_message(actual_assignments)
          )

          expected_assignments.each do |variable, expected_target|
            actual_target = actual_assignments[variable]&.name
            error_prefix = "The variable '#{variable}' must point to '#{expected_target}' instead '#{actual_target}'"

            assert_equal(
              expected_target,
              actual_target,
              debug_message(actual_assignments, error_prefix)
            )
          end
        end

        def debug_message(scope, prefix = '')
          output = [prefix]

          scope.each do |variable, target|
            output << " > variable: #{variable}"

            output << "   target > lookup: #{target.name} (#{target.lookups})"
            output << "          > scope:"

            target.scope.each do |sub_variable, sub_target|
              output << "            > #{sub_variable} -> #{sub_target.name}"
            end
          end

          output.join("\n")
        end
      end
    end
  end
end
