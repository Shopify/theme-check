# frozen_string_literal: true
require "zlib"

module ThemeCheck
  class AssetFile < ThemeFile
    def initialize(relative_path, storage)
      super
      @loaded = false
      @content = nil
    end

    alias_method :content, :source

    def gzipped_size
      @gzipped_size ||= Zlib.gzip(content).bytesize
    end

    def name
      relative_path.to_s
    end
  end
end
