# frozen_string_literal: true
module ThemeCheck
  class Packager
    ROOT = File.expand_path('../../..', __FILE__)
    PACKAGING_DIR = File.join(ROOT, 'packaging')
    BUILDS_DIR = File.join(PACKAGING_DIR, 'builds', ThemeCheck::VERSION)

    def initialize
      FileUtils.mkdir_p(BUILDS_DIR)
    end

    def build_homebrew
      root_dir = File.join(PACKAGING_DIR, 'homebrew')

      build_path = File.join(BUILDS_DIR, "theme-check.rb")
      puts "\nBuilding Homebrew package"

      puts "Generating formula..."
      File.delete(build_path) if File.exist?(build_path)

      spec_contents = File.read(File.join(root_dir, 'theme_check.base.rb'))
      spec_contents = spec_contents.gsub('THEME_CHECK_VERSION', ThemeCheck::VERSION)

      puts "Grabbing sha256 checksum from Rubygems.org"
      require 'digest/sha2'
      require 'open-uri'
      gem_checksum = URI.open("https://rubygems.org/downloads/theme-check-#{ThemeCheck::VERSION}.gem") do |io|
        Digest::SHA256.new.hexdigest(io.read)
      end

      puts "Got sha256 checksum for gem: #{gem_checksum}"
      spec_contents = spec_contents.gsub('THEME_CHECK_GEM_CHECKSUM', gem_checksum)

      puts "Writing generated formula\n  To: #{build_path}\n\n"
      File.write(build_path, spec_contents)
    end

    private

    def ensure_program_installed(program, installation_cmd)
      unless system(program, '--version', out: File::NULL, err: File::NULL)
        raise <<~MESSAGE

          Could not find program #{program} which is required to build the package.
          You can install it by running `#{installation_cmd}`.

        MESSAGE
      end
    end
  end
end
