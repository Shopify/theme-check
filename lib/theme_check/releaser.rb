# frozen_string_literal: true
require 'theme_check/version'

module ThemeCheck
  class Releaser
    ROOT = File.expand_path('../../..', __FILE__)
    LIB = File.join(ROOT, 'lib')

    class VersionError < StandardError; end

    def release(version)
      raise VersionError, "Missing version argument." if version.nil?
      raise VersionError, "Version should be a string." unless version.is_a?(String)
      raise VersionError, "Version should be a valid semver version." unless version =~ /^\d+\.\d+.\d+$/
      update_docs(version)
      update_version(version)
    end

    def update_version(version)
      version_file_path = File.join(LIB, 'theme_check/version.rb')
      version_file = File.read(version_file_path)
      updated_version_file = version_file.gsub(ThemeCheck::VERSION, version)

      return if updated_version_file == version_file
      puts "Updating version to #{version} in #{version_file_path}."
      File.write(version_file_path, updated_version_file)
    end

    def update_docs(version)
      Dir[ROOT + '/docs/checks/*.md'].each do |filename|
        doc_content = File.read(filename)
        updated_doc_content = doc_content.gsub('THEME_CHECK_VERSION', version)
        next if updated_doc_content == doc_content
        puts "Replacing `THEME_CHECK_VERSION` with #{version} in #{Pathname.new(filename).relative_path_from(ROOT)}"
        File.write(filename, updated_doc_content)
      end
    end
  end
end
