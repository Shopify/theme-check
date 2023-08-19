# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class Documentation
      class MarkdownTemplateTest < Minitest::Test
        def setup
          @markdown_template = MarkdownTemplate.new
        end

        def test_render
          entry = SourceIndex::ObjectEntry.new(
            'name' => 'product',
            'summary' => 'A product in the store.',
            'description' => 'A more detailed description of a product in the store.',
          )

          actual_template = @markdown_template.render(entry)
          expected_template = "### [product](https://shopify.dev/api/liquid/objects/product)\n" \
            "A product in the store.\n" \
            "\n---\n\n" \
            "A more detailed description of a product in the store."

          assert_equal(expected_template, actual_template)
        end

        def test_render_with_summary_only
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'summary' => 'A product in the store.'
          )

          actual_template = @markdown_template.render(entry)
          expected_template = "### [product](https://shopify.dev/api/liquid)\n" \
            "A product in the store." \

          assert_equal(expected_template, actual_template)
        end

        def test_render_with_description_only
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'description' => 'A more detailed description of a product in the store.'
          )

          actual_template = @markdown_template.render(entry)
          expected_template = "### [product](https://shopify.dev/api/liquid)\n" \
            "A more detailed description of a product in the store." \

          assert_equal(expected_template, actual_template)
        end

        def test_render_with_shopify_dev_urls
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'description' => <<~BODY
              When you render [...] [`include` tag](/api/liquid/tags#include) [...],
              [`if`](/api/liquid/tags#if) [`if`](/api/liquid/tags#if)
              [`unless`](/api/liquid/tags#unless) Allows you to specify a [...]
            BODY
          )

          actual_template = @markdown_template.render(entry)
          expected_template = "### [product](https://shopify.dev/api/liquid)\n" \
            "When you render [...] [`include` tag](https://shopify.dev/api/liquid/tags#include) [...],\n" \
            "[`if`](https://shopify.dev/api/liquid/tags#if) [`if`](https://shopify.dev/api/liquid/tags#if)\n" \
            "[`unless`](https://shopify.dev/api/liquid/tags#unless) Allows you to specify a [...]\n" \

          assert_equal(expected_template, actual_template)
        end

        def test_object_property_entry_title_link
          entry = SourceIndex::ObjectEntry.new(
            'name' => 'product',
            'properties' => [
              {
                "name" => "created_at",
                "summary" => "A timestamp for when the product was created.",
              },
            ]
          )

          actual_template = @markdown_template.render(entry.properties[0])
          expected_template = "### [created_at](https://shopify.dev/api/liquid/objects/product#product-created_at)\n" \
            "A timestamp for when the product was created."

          assert_equal(expected_template, actual_template)
        end

        def test_tag_entry_title_link
          entry = SourceIndex::TagEntry.new(
            "name" => "if",
            "summary" => "Renders an expression if a specific condition is `true`.",
          )

          actual_template = @markdown_template.render(entry)

          expected_template = "### [if](https://shopify.dev/api/liquid/tags/if)\n" \
            "Renders an expression if a specific condition is `true`."

          assert_equal(expected_template, actual_template)
        end

        def test_filter_title_link
          entry = SourceIndex::FilterEntry.new(
            "name" => "payment_type_img_url",
            "summary" => "Returns the URL for an SVG image of a given [payment type](/api/liquid/objects/shop#shop-enabled_payment_types).",
          )

          actual_template = @markdown_template.render(entry)

          expected_template = "### [payment_type_img_url](https://shopify.dev/api/liquid/filters/payment_type_img_url)\n" \
            "Returns the URL for an SVG image of a given [payment type](https://shopify.dev/api/liquid/objects/shop#shop-enabled_payment_types)."

          assert_equal(expected_template, actual_template)
        end

        def test_filter_parameter_entry_title_link
          entry = SourceIndex::FilterEntry.new(
            "name" => "stylesheet_tag",
            "summary" => "Generates an HTML `&lt;link&gt;` tag for a given resource URL.",
            "parameters" => [
              "description" => "The type of media that the resource applies to.",
              "name" => "media",
            ]
          )

          actual_template = @markdown_template.render(entry.parameters[0])

          expected_template = "### [media](https://shopify.dev/api/liquid/filters/media)\n" \
            "The type of media that the resource applies to."

          assert_equal(expected_template, actual_template)
        end
      end
    end
  end
end
