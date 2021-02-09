# frozen_string_literal: true

# An in-memory theme is not written to disk. The reasons why you'd
# want to do that are your own. The idea is to not write to disk
# something that doesn't need to be there. If you have your template
# as a big hash already, leave it like that and save yourself some IO.
module ThemeCheck
  class InMemoryTheme < Theme
    LIQUID_REGEX = /\.liquid$/
    JSON_REGEX = /\.json$/

    def initialize(files)
      @files = files
    end

    def liquid
      @liquid ||= @files
        .select { |path, _v| LIQUID_REGEX.match?(path) }
        .map { |path, content| InMemoryTemplate.new(path, content) }
    end

    def json
      @json ||= @files
        .select { |k, _v| JSON_REGEX.match?(k) }
        .map { |path, content| InMemoryJsonFile.new(path, content) }
    end

    def directories
      @directories ||= @files
        .map { |k, _v| Pathname(File.dirname(k)) }
        .uniq
    end
  end

  class InMemoryTemplateNoRootError < StandardError; end
end
