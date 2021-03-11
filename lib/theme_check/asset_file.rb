# frozen_string_literal: true
require "pathname"
require "zlib"

module ThemeCheck
  class AssetFile
    def initialize(relative_path, storage)
      @relative_path = relative_path
      @storage = storage
      @loaded = false
      @content = nil
    end

    def path
      @storage.path(@relative_path)
    end

    def relative_path
      @relative_pathname ||= Pathname.new(@relative_path)
    end

    def content
      @content ||= @storage.read(@relative_path)
    end

    def gzipped_size
      @gzipped_size ||= Zlib.gzip(content).bytesize
    end

    def name
      relative_path.to_s
    end
  end
end
