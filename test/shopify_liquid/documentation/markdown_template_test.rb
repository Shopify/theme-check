# frozen_string_literal: true

require 'test_helper'

module ThemeCheck
  module ShopifyLiquid
    class Documentation
      class MarkdownTemplateTest < Minitest::Test
        def setup
          @markdown_template = MarkdownTemplate.new
        end

        def test_render
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'summary' => 'A product in the store.',
            'description' => 'A more detailed description of a product in the store.',
          )

          actual_temaplte = @markdown_template.render(entry)
          expected_template = "### product\n" \
            "A product in the store.\n" \
            "\n--\n\n" \
            "A more detailed description of a product in the store."

          assert_equal(expected_template, actual_temaplte)
        end

        def test_render_with_summary_only
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'summary' => 'A product in the store.'
          )

          actual_temaplte = @markdown_template.render(entry)
          expected_template = "### product\n" \
            "A product in the store." \

          assert_equal(expected_template, actual_temaplte)
        end

        def test_render_with_description_only
          entry = SourceIndex::BaseEntry.new(
            'name' => 'product',
            'description' => 'A more detailed description of a product in the store.'
          )

          actual_temaplte = @markdown_template.render(entry)
          expected_template = "### product\n" \
            "A more detailed description of a product in the store." \

          assert_equal(expected_template, actual_temaplte)
        end
      end
    end
  end
end
