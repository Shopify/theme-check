# frozen_string_literal: true

require 'pathname'

module ThemeCheck
  module ShopifyLiquid
    module SourceManager
      extend self

      def download_or_refresh_files
        download if !has_required_files? || refresh_needed?
      end

      def download
        create_destination unless destination_exist?

        required_file_names.each do |file_name|
          download_file(local_path(file_name), remote_path(file_name))
        end
      end

      def refresh_needed?
        if remote_revision != local_revision
          return true
        end

        false 
      end

      def local_path(file_name)
        documentation_directory + "#{file_name}.json"
      end

      private

      DOCUMENTATION_FETCH_URL = "https://github.com/Shopify/theme-liquid-docs/raw/main/data"
      DOCUMENTATION_DIRECTORY = Pathname.new("#{__dir__}/../../../data/shopify_liquid/documentation")
      REQUIRED_FILE_NAMES = [:filters, :objects, :tags, :latest].freeze

      def local_revision
        local_revision_file = local_path(:latest).read

        # raise an error if revision isn't found to avoid returning nil
        JSON.parse(local_revision_file).fetch('revision')
      end

      def remote_revision
        remote_revision_file = open_uri(remote_path(:latest))

        # raise an error if revision isn't found to avoid returning nil
        JSON.parse(remote_revision_file).fetch('revision')
      end

      def remote_path(file_name)
        "#{documentation_fetch_url}/#{file_name}.json"
      end

      def download_file(local, remote)
        File.open(local, "wb") do |file|
          content = open_uri(remote)

          file.write(content)
        end
      end

      def open_uri(remote)
        # require at usage point to not slow down theme-check on startup
        require 'open-uri'

        URI.parse(remote).open.read
      end

      def destination_exist?
        documentation_directory.exist?
      end

      def create_destination
        Dir.mkdir(documentation_directory)
      end

      def documentation_directory
        DOCUMENTATION_DIRECTORY
      end

      def documentation_fetch_url
        DOCUMENTATION_FETCH_URL
      end

      def required_file_names
        REQUIRED_FILE_NAMES
      end

      def has_required_files?
        required_file_names.all? { |file_name| local_path(file_name).exist? }
      end
    end
  end
end
