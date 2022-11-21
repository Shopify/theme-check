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

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      TYPE_SOURCE = Pathname.new("#{__dir__}/../../../data/shopify_liquid/documentation")

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
          read_json(file_path(file_name))
        end

        def read_json(path)
          download_files unless has_files?

          JSON.parse(path.read)
        end

        # TODO: (1/6) https://github.com/Shopify/theme-check/issues/651
        # -
        # Remove this implementation in favor of a proper/stable approach to
        # download/update theme-liquid-docs files.
        def download_files
          require 'open-uri'

          documentation_directory = "#{__dir__}/../../../data/shopify_liquid/documentation"

          Dir.mkdir(documentation_directory) unless File.exist?(documentation_directory)

          ['filters', 'objects', 'tags'].each do |file_name|
            local_path = "#{documentation_directory}/#{file_name}.json"
            remote_path = "https://github.com/Shopify/theme-liquid-docs/raw/main/data/#{file_name}.json"

            File.open(local_path, "wb") do |file|
              content = URI.open(remote_path).read # rubocop:disable Security/Open
              file.write(content)
            end
          end
        end

        def has_files?
          [:filters, :objects, :tags].all? { |file_name| file_path(file_name).exist? }
        end

        def file_path(file_name)
          TYPE_SOURCE + "#{file_name}.json"
        end

        def built_in_objects
          load_file("../built_in_liquid_objects")
        end
      end
    end
  end
end
