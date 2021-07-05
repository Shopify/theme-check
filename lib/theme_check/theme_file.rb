# frozen_string_literal: true
require "pathname"

module ThemeCheck
  class ThemeFile
    def initialize(relative_path, storage)
      @relative_path = relative_path
      @storage = storage
    end

    def path
      @storage.path(@relative_path)
    end

    def relative_path
      @relative_pathname ||= Pathname.new(@relative_path)
    end

    def name
      relative_path.sub_ext('').to_s
    end

    def source
      @source ||= @storage.read(@relative_path)
    end

    def json?
      false
    end

    def liquid?
      false
    end

    def ==(other)
      other.is_a?(self.class) && relative_path == other.relative_path
    end
    alias_method :eql?, :==
  end
end
