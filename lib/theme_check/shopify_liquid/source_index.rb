# frozen_string_literal: true

require 'json'
require 'pathname'

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class << self
        def filters
          @filters = nil if FilterState.outdated?

          @filters ||= FilterState.mark_up_to_date &&
            load_file(:filters)
              .map { |hash| FilterEntry.new(hash) }
        end

        def objects
          @objects = nil if ObjectState.outdated?

          @objects ||= ObjectState.mark_up_to_date &&
            load_file(:objects)
              .concat(built_in_objects)
              .map { |hash| ObjectEntry.new(hash) }
        end

        def tags
          @tags = nil if TagState.outdated?

          @tags ||= TagState.mark_up_to_date &&
            load_file(:tags)
              .map { |hash| TagEntry.new(hash) }
        end

        private

        def load_file(file_name)
          read_json(local_path!(file_name))
        end

        def local_path!(file_name)
          SourceManager.download unless SourceManager.has_required_files?
          SourceManager.local_path(file_name)
        end

        def read_json(path)
          JSON.parse(path.read)
        end

        def built_in_objects
          load_file('../built_in_liquid_objects')
        end
      end
    end
  end
end
