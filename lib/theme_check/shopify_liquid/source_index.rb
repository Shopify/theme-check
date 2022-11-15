# frozen_string_literal: true

require 'json'
require 'pathname'

require_relative 'source_index/base_entry'
require_relative 'source_index/filter_entry'
require_relative 'source_index/object_entry'
require_relative 'source_index/parameter_entry'
require_relative 'source_index/property_entry'
require_relative 'source_index/return_type_entry'
require_relative 'source_index/tag_entry'

require_relative './source_manager'

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class << self
        def filters
          @filters ||= load_file(:filters)
            .map { |hash| SourceIndex::FilterEntry.new(hash) }
        end

        def objects
          @objects ||= load_file(:objects)
            .concat(built_in_objects)
            .map { |hash| SourceIndex::ObjectEntry.new(hash) }
        end

        def tags
          @tags ||= load_file(:tags)
            .map { |hash| SourceIndex::TagEntry.new(hash) }
        end

        private

        def load_file(file_name)
          read_json(SourceManager.local_path(file_name))
        end

        def read_json(path)
          SourceManager.download_or_refresh_files

          JSON.parse(path.read)
        end

        def built_in_objects
          # TODO: (2/6) https://github.com/Shopify/theme-check/issues/657
          # -
          # Manualy introduce a 'data/shopify_liquid/built_in_liquid_objects.json' file
          # using https://shopify.dev/api/liquid/basics#types as a reference.
          # -
          [
            {
              'properties' => [
                { 'name' => 'first', 'description' => 'Returns the first item of an array.' },
                { 'name' => 'size', 'description' => 'Returns the number of items in an array.' },
                { 'name' => 'last', 'description' => 'Returns the last item of an array.' },
              ],
              'name' => 'array',
              'description' => 'Arrays hold lists of variables of any type.',
            },
            {
              'properties' => [
                {
                  'name' => 'size',
                  'description' => 'Returns the number of characters in a string.',
                },
              ],
              'name' => 'string',
              'description' => 'Strings are sequences of characters wrapped in single or double quotes.',
            },
          ]
        end
      end
    end
  end
end
