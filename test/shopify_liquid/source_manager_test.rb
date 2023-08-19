# frozen_string_literal: true

require 'test_helper'
require_relative './source_test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceManagerTest < Minitest::Test
      include SourceTestHelper

      def setup
        @source_manager_class = SourceTestHelper::FakeSourceManager.dup
        @tmp_dir = @source_manager_class.default_destination
      end

      def test_refresh_files_after_files_are_out_of_date
        create_documentation_in_destination(@tmp_dir)
        create_dummy_tags_file(@tmp_dir)
        create_out_of_date_revision_file(@tmp_dir)

        download_or_refresh_files

        assert_test_documentation_up_to_date(@tmp_dir)
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_download_or_refresh_noop_when_docs_up_to_date
        create_documentation_in_destination(@tmp_dir)

        @source_manager_class.expects(:download).never

        download_or_refresh_files
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_download_creates_directory
        tmp_dir = Pathname.new("#{@tmp_dir}/new")

        @source_manager_class.stubs(:default_destination).returns(tmp_dir)

        download_or_refresh_files

      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_download_when_a_request_error_happens
        tmp_dir = Pathname.new("#{@tmp_dir}/new")

        @source_manager_class.stubs(:open_uri).raises(SourceManager::DownloadResourceError)
        @source_manager_class.stubs(:default_destination).returns(tmp_dir)

        # Nothing is raised
        download_or_refresh_files
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_download_overwrites_existing_directory
        create_dummy_tags_file(@tmp_dir)

        download_or_refresh_files

        assert_test_documentation_up_to_date(@tmp_dir)
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_has_files_returns_false_in_directory_that_does_not_exist
        refute(@source_manager_class.send(:has_required_files?, Pathname.new("/path/does/not/exist")))
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_has_files_returns_false_when_not_all_files_present
        create_dummy_tags_file(@tmp_dir)

        refute(@source_manager_class.send(:has_required_files?, @source_manager_class.default_destination))
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      def test_has_files_returns_true
        create_documentation_in_destination(@tmp_dir)

        assert(@source_manager_class.send(:has_required_files?, @source_manager_class.default_destination))
      ensure
        FileUtils.remove_entry(@tmp_dir)
      end

      private

      def assert_test_documentation_up_to_date(destination)
        assert_equal(objects_content, File.read(destination + "objects.json"))
        assert_equal(filters_content, File.read(destination + "filters.json"))
        assert_equal(tags_content, File.read(destination + "tags.json"))
        assert_equal(revision_content, File.read(destination + "latest.json"))

        downloaded_files = Dir.glob(destination + '*')
          .select { |file| File.file?(file) }
          .map { |file| File.basename(file) }
          .to_set

        assert_equal(["filters.json", "objects.json", "tags.json", "latest.json"].to_set, downloaded_files)
      end

      def download_or_refresh_files
        @source_manager_class.download_or_refresh_files
        @source_manager_class.wait_downloads
      end
    end
  end
end
