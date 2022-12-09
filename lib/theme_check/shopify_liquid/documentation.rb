# frozen_string_literal: true

require_relative 'documentation/markdown_template'

module ThemeCheck
  module ShopifyLiquid
    class Documentation
      class << self
        def filter_doc(filter_name)
          render_doc(SourceIndex.filters.find { |entry| entry.name == filter_name })
        end

        def object_doc(object_name)
          render_doc(SourceIndex.objects.find { |entry| entry.name == object_name })
        end

        def tag_doc(tag_name)
          render_doc(SourceIndex.tags.find { |entry| entry.name == tag_name })
        end

        def object_property_doc(object_name, property_name)
          property_entry = SourceIndex
            .objects
            .find { |entry| entry.name == object_name }
            &.properties
            &.find { |prop| prop.name == property_name }

          render_doc(property_entry)
        end

        def render_doc(entry)
          return nil unless entry
          markdown_template.render(entry)
        end

        private

        def markdown_template
          @markdown_template ||= MarkdownTemplate.new
        end
      end
    end
  end
end
