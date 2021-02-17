# frozen_string_literal: true

# An in-memory storage is not written to disk. The reasons why you'd
# want to do that are your own. The idea is to not write to disk
# something that doesn't need to be there. If you have your template
# as a big hash already, leave it like that and save yourself some IO.
module ThemeCheck
  class InMemoryStorage < Storage
    def initialize(files = {})
      @files = files
    end

    def path(name)
      name
    end

    def read(name)
      @files[name]
    end

    def write(name, content)
      @files[name] = content
    end

    def files
      @values ||= @files.keys
    end

    def directories
      @directories ||= @files
        .keys
        .flat_map { |relative_path| Pathname.new(relative_path).ascend.to_a }
        .map(&:to_s)
        .uniq
    end
  end
end
