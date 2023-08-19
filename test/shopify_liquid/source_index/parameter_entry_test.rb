# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class ParameterEntryTest < Minitest::Test
        def setup
          @entry = ParameterEntry.new(hash)
        end

        def test_summary
          assert_nil(@entry.summary)
        end

        def test_return_type
          assert_equal('string', @entry.return_type)
        end

        private

        def hash
          {
            'name' => 'media',
            'description' => 'The type of media that the resource [...]',
            'required' => false,
            'types' => ['string'],
          }
        end
      end
    end
  end
end
