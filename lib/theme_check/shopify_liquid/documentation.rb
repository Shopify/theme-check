# frozen_string_literal: true

require_relative 'documentation/markdown_template'

module ThemeCheck
  module ShopifyLiquid
    class Documentation
      class << self
        def filter_doc(filter_name)
          render_doc(ScopeIndex.filters.find { |entry| entry.name == filter_name })
        end

        def object_doc(object_name)
          render_doc(ScopeIndex.objects.find { |entry| entry.name == object_name })
        end

        def tag_doc(tag_name)
          render_doc(ScopeIndex.tags.find { |entry| entry.name == tag_name })
        end

        def object_property_doc(object_name, property_name)
          property_entry = ScopeIndex
            .objects
            .find { |entry| entry.name == object_name }
            &.properties
            &.find { |prop| prop.name == property_name }

          render_doc(property_entry)
        end

        private

        def render_doc(entry)
          return nil unless entry
          markdown_template.render(entry)
        end

        def markdown_template
          @markdown_template ||= MarkdownTemplate.new
        end
      end
    end
  end
end
