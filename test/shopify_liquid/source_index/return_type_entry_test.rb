# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class ReturnTypeEntryTest < Minitest::Test
        def test_to_s
          entry = ReturnTypeEntry.new('type' => 'string')
          assert_equal('string', entry.to_s)
        end

        def test_array_type
          entry = ReturnTypeEntry.new('type' => 'array', 'array_value' => 'image')
          assert_equal('image', entry.array_type)
        end

        def test_is_array_type_when_it_returns_true
          entry = ReturnTypeEntry.new('type' => 'array', 'array_value' => 'image')
          assert(entry.array_type?)
        end

        def test_is_array_type_when_it_returns_false
          entry = ReturnTypeEntry.new('type' => 'string', 'array_value' => '')
          refute(entry.array_type?)
        end
      end
    end
  end
end
