# frozen_string_literal: true

require 'pathname'

module ThemeCheck
  module ShopifyLiquid
    module SourceManager
      extend self

      def download_or_refresh_files
        if has_required_files?
          # TODO: https://github.com/Shopify/theme-check/issues/651
          #
          # Refresh files if they exist locally
        else
          download
        end
      end

      def download
        create_destination unless destination_exist?

        required_file_names.each do |file_name|
          download_file(local_path(file_name), remote_path(file_name))
        end
      end

      def local_path(file_name)
        documentation_directory + "#{file_name}.json"
      end

      private

      DOCUMENTATION_FETCH_URL = "https://github.com/Shopify/theme-liquid-docs/raw/main/data"
      DOCUMENTATION_DIRECTORY = Pathname.new("#{__dir__}/../../../data/shopify_liquid/documentation")
      REQUIRED_FILE_NAMES = [:filters, :objects, :tags].freeze

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
