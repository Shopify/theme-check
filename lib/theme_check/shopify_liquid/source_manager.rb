# frozen_string_literal: true

require 'net/http'
require 'pathname'
require 'tmpdir'

module ThemeCheck
  module ShopifyLiquid
    class SourceManager
      REQUIRED_FILE_NAMES = [:filters, :objects, :tags, :latest].freeze

      class << self
        def download_or_refresh_files(destination = default_destination)
          if has_required_files?(destination)
            refresh(destination)
          else
            download(destination)
          end
        end

        def download(destination = default_destination)
          Dir.mkdir(destination) unless destination.exist?

          REQUIRED_FILE_NAMES.each do |file_name|
            download_file(local_path(file_name, destination), remote_path(file_name))
          end
        end

        def refresh(destination = default_destination)
          refresh_threads << Thread.new { refresh_thread(destination) }
        end

        def local_path(file_name, destination = default_destination)
          destination + "#{file_name}.json"
        end

        def has_required_files?(destination = default_destination)
          REQUIRED_FILE_NAMES.all? { |file_name| local_path(file_name, destination).exist? }
        end

        def wait_downloads
          refresh_threads.each(&:join)
        end

        private

        def refresh_thread(destination)
          return unless refresh_needed?(destination)

          Dir.mktmpdir do |tmp_dir|
            download(Pathname.new(tmp_dir))

            FileUtils.cp_r("#{tmp_dir}/.", destination)

            mark_all_indexes_outdated
          end
        end

        def refresh_needed?(destination)
          local_latest_content = local_path(:latest, destination).read
          remote_latest_content = open_uri(remote_path(:latest))

          revision(local_latest_content) != revision(remote_latest_content)
        end

        def revision(json_content)
          # Raise an error if revision isn't found to avoid returning nil
          JSON.parse(json_content).fetch('revision')
        end

        def remote_path(file_name)
          "https://raw.githubusercontent.com/Shopify/theme-liquid-docs/main/data/#{file_name}.json"
        end

        def download_file(local_path, remote_uri)
          File.open(local_path, "wb") do |file|
            content = open_uri(remote_uri)
            file.write(content)
          end
        end

        def mark_all_indexes_outdated
          SourceIndex::FilterState.mark_outdated
          SourceIndex::ObjectState.mark_outdated
          SourceIndex::TagState.mark_outdated
        end

        # State

        def default_destination
          @default_destination ||= Pathname.new("#{__dir__}/../../../data/shopify_liquid/documentation")
        end

        def refresh_threads
          @refresh_threads ||= []
        end

        def open_uri(uri_str)
          uri = URI.parse(uri_str)

          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            req = Net::HTTP::Get.new(uri)
            http.request(req)
          end

          res.body
        end
      end
    end
  end
end
