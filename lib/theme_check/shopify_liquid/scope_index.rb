# frozen_string_literal: true

require 'json'
require 'pathname'

require_relative 'scope_index/base_entry'
require_relative 'scope_index/filter_entry'
require_relative 'scope_index/object_entry'
require_relative 'scope_index/parameter_entry'
require_relative 'scope_index/property_entry'
require_relative 'scope_index/return_type_entry'
require_relative 'scope_index/tag_entry'

module ThemeCheck
  module ShopifyLiquid
    class ScopeIndex
      TYPE_SOURCE = Pathname.new("#{__dir__}/../../../data/shopify_liquid/documentation")

      class << self
        def filters
          @filters ||= load_file(:filters).map { |hash| ScopeIndex::FilterEntry.new(hash) }
        end

        def objects
          @objects ||= load_file(:objects).map { |hash| ScopeIndex::ObjectEntry.new(hash) }
        end

        def tags
          @tags ||= load_file(:tags).map { |hash| ScopeIndex::TagEntry.new(hash) }
        end

        private

        def load_file(file_name)
          read_json(file_path(file_name))
        end

        def read_json(path)
          download_files unless has_files?

          JSON.parse(path.read)
        end

        def download_files
          ################################################################################
          ## TODO (REMOVE ME):
          ##   Remove this implementation in favor of a proper/stable approach
          ##   to download/update theme-liquid-docs files.
          ################################################################################
          commands = [
            'git clone git@github.com:Shopify/theme-liquid-docs.git /tmp/theme-liquid-docs-tmp',
            'cd /tmp/theme-liquid-docs-tmp',
            'git reset origin/init-repo --hard',
            "mv data/filters.json #{__dir__}/../../../data/shopify_liquid/documentation",
            "mv data/objects.json #{__dir__}/../../../data/shopify_liquid/documentation",
            "mv data/tags.json #{__dir__}/../../../data/shopify_liquid/documentation",
            'cd -',
          ].join(' && ')

          Kernel.exec(commands)
        end

        def has_files?
          [:filters, :objects, :tags].all? { |file_name| file_path(file_name).exist? }
        end

        def file_path(file_name)
          TYPE_SOURCE + "#{file_name}.json"
        end
      end
    end
  end
end
