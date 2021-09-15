# frozen_string_literal: true
require "zlib"

module ThemeCheck
  class AssetFile < ThemeFile
    def initialize(relative_path, storage)
      super
      @loaded = false
      @content = nil
    end

    def rewriter
      @rewriter ||= ThemeFileRewriter.new(@relative_path, source)
    end

    def write
      content = rewriter.to_s
      if source != content
        @storage.write(@relative_path, content.gsub("\n", @eol))
        @source = content
        @rewriter = nil
      end
    end

    def gzipped_size
      @gzipped_size ||= Zlib.gzip(source).bytesize
    end

    def name
      relative_path.to_s
    end
  end
end
