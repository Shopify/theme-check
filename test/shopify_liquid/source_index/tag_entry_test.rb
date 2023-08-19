# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class TagEntryTest < Minitest::Test
        def setup
          @entry = TagEntry.new(hash)
        end

        def test_parameters
          assert(@entry.parameters.any?)
        end

        private

        def hash
          {
            'category' => 'iteration',
            'description' => 'The "tablerow" tag must be wrapped in HTML "table" [...]',
            'parameters' => [
              { 'description' => 'The number of columns that  [...]', 'name' => 'cols', 'required' => false, 'types' => ['number'] },
              { 'description' => 'The number of iterations to [...]', 'name' => 'limit', 'required' => false, 'types' => ['number'] },
              { 'description' => 'The 1-based index to start  [...]', 'name' => 'offset', 'required' => false, 'types' => ['number'] },
              { 'description' => 'A custom numeric range to   [...]', 'name' => 'range', 'required' => false, 'types' => ['untyped'] },
            ],
            'summary' => 'Generates HTML table rows for every item in an array.',
            'name' => 'tablerow',
            'syntax' => '{% tablerow variable in array %} expression {% endtablerow %}',
            'syntax_keywords' => [
              { 'keyword' => 'variable', 'description' => 'The current item in the array.' },
              { 'keyword' => 'array', 'description' => 'The array to iterate over.' },
              { 'keyword' => 'expression', 'description' => 'The expression to render.' },
            ],
            'examples' => [
              {
                'name' => 'cols',
                'description' => 'You can define how many columns the table should have using the "cols" parameter.',
                'syntax' => '{% tablerow variable in array cols: number %} expression {% endtablerow %}',
                'path' => '/collections/sale-potions',
                'raw_liquid' => '[...]',
                'parameter' => true,
                'display_type' => 'text',
                'show_data_tab' => true,
              },
            ],
          }
        end
      end
    end
  end
end
