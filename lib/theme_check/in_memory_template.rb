# frozen_string_literal: true

module ThemeCheck
  class InMemoryTemplate < Template
    attr_reader :path
    attr_accessor :source

    def initialize(path, source)
      @path = Pathname(path)
      @source = source
    end

    def relative_path
      @path
    end

    def write
      @source = lines.join("\n")
    end
  end
end
