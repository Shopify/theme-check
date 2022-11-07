# frozen_string_literal: true

require 'test_helper'

module ThemeCheck
  module ShopifyLiquid
    class SourceIndexTest < Minitest::Test
      def test_filters
        assert_entries(SourceIndex.filters)
      end

      def test_objects
        assert_entries(SourceIndex.objects)
      end

      def test_tags
        assert_entries(SourceIndex.tags)
      end

      def test_built_in_objects
        names = SourceIndex.objects.map(&:name)

        assert_includes(names, 'array')
        assert_includes(names, 'string')
      end

      private

      def assert_entries(entries)
        has_entries = !entries.empty?
        has_names = entries.map(&:name).all? { |n| !n.empty? }
        has_bodies = entries.all? { |e| !e.description.empty? || !e.summary.empty? }

        assert(has_entries, "at least one entry must exist")
        assert(has_names, "all entries must have a name")
        assert(has_bodies, "all entries must have a body")
      end
    end
  end
end
