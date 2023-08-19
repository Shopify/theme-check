# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class FilterEntryTest < Minitest::Test
        def setup
          @entry = FilterEntry.new(hash)
        end

        def test_parameters
          assert(@entry.parameters.any?)
        end

        def test_return_type
          assert_equal('string', @entry.return_type)
        end

        private

        def hash
          {
            'description' => '',
            'parameters' => [
              {
                'description' => 'The type of media that the resource [...]',
                'name' => 'media',
                'types' => ['string'],
              },
              {
                'description' => 'Whether the resource should be [...]',
                'name' => 'preload',
                'types' => ['boolean'],
              },
            ],
            'return_type' => [{ 'type' => 'string' }],
            'examples' => [],
            'summary' => 'Generates an HTML "link" tag for a given resource URL [...]',
            'syntax' => 'string | stylesheet_tag',
            'name' => 'stylesheet_tag',
          }
        end
      end
    end
  end
end
