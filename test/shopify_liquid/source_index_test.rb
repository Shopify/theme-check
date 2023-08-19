# frozen_string_literal: true

require 'test_helper'
require_relative './source_test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndexTest < Minitest::Test
      include SourceTestHelper

      def test_filters
        assert_entries(SourceIndex.filters)
      end

      def test_filters_refresh
        setup_refresh_test

        # Stub documentation directory to load production data
        @source_index_class
          .stubs(:default_destination)
          .returns(SourceManager.send(:default_destination))
        @source_index_class.filters
        assert_operator(@source_index_class.filters.length, :>=, 138)

        SourceIndex::FilterState.mark_outdated
        assert(SourceIndex::FilterState.outdated?)

        # Stub documentation directory to load test fixture data
        @source_index_class.stubs(:default_destination).returns(@pathname_tmp_dir)

        # Confirm filters reloads
        @source_index_class.filters
        assert_equal(1, @source_index_class.filters.length)
        refute(SourceIndex::FilterState.outdated?)
      ensure
        FileUtils.remove_entry(@pathname_tmp_dir)
      end

      def test_objects
        assert_entries(SourceIndex.objects)
      end

      def test_objects_refresh
        setup_refresh_test

        # Stub documentation directory to load production data
        @source_index_class
          .stubs(:default_destination)
          .returns(SourceManager.send(:default_destination))
        @source_index_class.objects
        assert_operator(@source_index_class.objects.length, :>=, 111)

        SourceIndex::ObjectState.mark_outdated
        assert(SourceIndex::ObjectState.outdated?)

        # Stub documentation directory to load test fixture data
        @source_index_class.stubs(:default_destination).returns(@pathname_tmp_dir)

        # Confirm objects reloads
        @source_index_class.objects
        assert_equal(1, @source_index_class.objects.length)
        refute(SourceIndex::ObjectState.outdated?)
      ensure
        FileUtils.remove_entry(@pathname_tmp_dir)
      end

      def test_tags
        assert_entries(SourceIndex.tags)
      end

      def test_tags_refresh
        setup_refresh_test

        # Stub documentation directory to load production data
        @source_index_class
          .stubs(:default_destination)
          .returns(SourceManager.send(:default_destination))
        @source_index_class.tags
        assert_operator(@source_index_class.tags.length, :>=, 27)

        SourceIndex::TagState.mark_outdated
        assert(SourceIndex::TagState.outdated?)

        # Stub documentation directory to load test fixture data
        @source_index_class.stubs(:default_destination).returns(@pathname_tmp_dir)

        # Confirm tags reloads
        @source_index_class.tags
        assert_equal(1, @source_index_class.tags.length)
        refute(SourceIndex::TagState.outdated?)
      ensure
        FileUtils.remove_entry(@pathname_tmp_dir)
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

      def setup_refresh_test
        @source_index_class = SourceTestHelper::FakeSourceIndex.dup
        @pathname_tmp_dir = @source_index_class.default_destination
        create_documentation_in_destination(@pathname_tmp_dir)
      end
    end
  end
end
