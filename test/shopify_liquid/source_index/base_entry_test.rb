# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class BaseEntryTest < Minitest::Test
        def test_hash
          assert_equal(default_hash, entry.hash)
        end

        def test_hash_with_nil_hashes
          assert_equal({}, entry(nil).hash)
        end

        def test_name
          assert_equal('product', entry.name)
        end

        def test_summary
          assert_equal('A product in the store.', entry.summary)
        end

        def test_summary_without_summary
          assert_equal('', entry(nil).summary)
        end

        def test_description
          assert_equal('A more detailed description of a product in the store.', entry.description)
        end

        def test_description_without_description
          assert_equal('', entry(nil).description)
        end

        private

        def entry(hash = default_hash)
          BaseEntry.new(hash)
        end

        def default_hash
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
