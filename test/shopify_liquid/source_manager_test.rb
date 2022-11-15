# frozen_string_literal: true

require 'test_helper'

module ThemeCheck
  module ShopifyLiquid
    class SourceManagerTest < Minitest::Test
      # Use a documentation folder in the test/ directory
      SOURCE_DOCUMENTATION_DIRECTORY = Pathname.new("#{__dir__}/../data/shopify_liquid/documentation")
      TEST_DOCUMENTATION_DIRECTORY = Pathname.new("#{__dir__}/../data/shopify_liquid/documentation/tmp")

      def setup
        SourceManager.stubs(:documentation_directory).returns(TEST_DOCUMENTATION_DIRECTORY)
        SourceManager.stubs(:open_uri).with(objects_uri).returns(objects_content)
        SourceManager.stubs(:open_uri).with(filters_uri).returns(filters_content)
        SourceManager.stubs(:open_uri).with(tags_uri).returns(tags_content)
      end

      def test_download_creates_directory
        SourceManager.download

        assert_download_succeeded
      ensure
        remove_test_documentation
      end

      def test_download_overwrites_existing_directory
        create_dummy_tags_file

        SourceManager.download

        assert_download_succeeded
      ensure
        remove_test_documentation
      end

      def test_has_files_returns_false_in_directory_that_does_not_exist
        refute(SourceManager.send(:has_required_files?))
      end

      def test_has_files_returns_false_when_not_all_files_present
        create_dummy_tags_file

        refute(SourceManager.send(:has_required_files?))
      ensure
        remove_test_documentation
      end

      def test_has_files_returns_true
        SourceManager.stubs(:documentation_directory).returns(SOURCE_DOCUMENTATION_DIRECTORY)

        assert(SourceManager.send(:has_required_files?))
      end

      private

      def assert_download_succeeded
        assert_equal(objects_content, File.read(TEST_DOCUMENTATION_DIRECTORY + "objects.json"))
        assert_equal(filters_content, File.read(TEST_DOCUMENTATION_DIRECTORY + "filters.json"))
        assert_equal(tags_content, File.read(TEST_DOCUMENTATION_DIRECTORY + "tags.json"))

        downloaded_files = Dir.glob(TEST_DOCUMENTATION_DIRECTORY + '*')
          .select { |file| File.file?(file) }
          .map { |file| File.basename(file) }
          .to_set

        assert_equal(["filters.json", "objects.json", "tags.json"].to_set, downloaded_files)
      end

      def objects_uri
        @objects_uri ||= "https://github.com/Shopify/theme-liquid-docs/raw/main/data/objects.json"
      end

      def filters_uri
        @filters_uri ||= "https://github.com/Shopify/theme-liquid-docs/raw/main/data/filters.json"
      end

      def tags_uri
        @tags_uri ||= "https://github.com/Shopify/theme-liquid-docs/raw/main/data/tags.json"
      end

      def objects_content
        @objects_content ||= load_file(:objects)
      end

      def filters_content
        @filters_content ||= load_file(:filters)
      end

      def tags_content
        @tags_content ||= load_file(:tags)
      end

      def remove_test_documentation
        return unless TEST_DOCUMENTATION_DIRECTORY.exist?

        TEST_DOCUMENTATION_DIRECTORY.rmtree
      end

      def load_file(file_name)
        path = SOURCE_DOCUMENTATION_DIRECTORY + "#{file_name}.json"
        raise "File not found: #{path}" unless File.file?(path)
        File.read(path)
      end

      def create_dummy_tags_file
        Dir.mkdir(TEST_DOCUMENTATION_DIRECTORY) unless TEST_DOCUMENTATION_DIRECTORY.exist?
        File.open(TEST_DOCUMENTATION_DIRECTORY + 'tags.json', "wb") do |file|
          file.write({})
        end
      end
    end
  end
end
