# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class ObjectEntryTest < Minitest::Test
        def setup
          @entry = ObjectEntry.new(hash)
        end

        def test_properties
          assert(@entry.properties.any?)
        end

        def test_return_type
          assert_equal('array', @entry.return_type)
        end

        private

        def hash
          {
            'description' => 'Tip: Use the "image_url" and "image_tag" filters to display images on the storefront.',
            'properties' => [
              {
                'description' => '',
                'examples' => [],
                'return_type' => [{ 'type' => 'string' }],
                'summary' => 'The relative URL of the image.',
                'name' => 'src',
              },
              {
                'description' => 'The "media_type" property is only available for images accessed through the following sources [...]',
                'examples' => [{ 'name' => 'Filter for media', 'description' => 'You can use the "media_type" property  [...]' }],
                'return_type' => [{ 'type' => 'string' }],
                'summary' => 'The media type of the image. Always returns "image".',
                'name' => 'media_type',
              },
            ],
            'summary' => 'An image, such as a product or collection image.',
            'name' => 'image',
            'return_type' => [{ 'type' => 'array', 'name' => '', 'description' => '', 'array_value' => 'image' }],
          }
        end
      end
    end
  end
end
