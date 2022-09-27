# frozen_string_literal: true

require 'test_helper'

module ThemeCheck
  module ShopifyLiquid
    class ScopeIndex
      class BaseEntryTest < Minitest::Test
        def setup
          @entry = BaseEntry.new(hash)
        end

        def test_hash
          assert_equal(hash, @entry.hash)
        end

        def test_name
          assert_equal('product', @entry.name)
        end

        def test_summary
          assert_equal('A product in the store.', @entry.summary)
        end

        def test_description
          assert_equal('A more detailed description of a product in the store.', @entry.description)
        end

        private

        def hash
          {
            'name' => 'product',
            'summary' => 'A product in the store.',
            'description' => 'A more detailed description of a product in the store.',
          }
        end
      end
    end
  end
end
