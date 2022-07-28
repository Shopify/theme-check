# frozen_string_literal: true

# An in-memory storage is not written to disk. The reasons why you'd
# want to do that are your own. The idea is to not write to disk
# something that doesn't need to be there. If you have your theme
# as a big hash already, leave it like that and save yourself some IO.
module ThemeCheck
  class InMemoryStorage < Storage
    attr_reader :root

    def initialize(files = {}, root = "/dev/null")
      @files = files # Hash<String, String>
      @root = Pathname.new(root)
    end

    def path(relative_path)
      @root.join(relative_path)
    end

    def read(relative_path)
      @files[relative_path]
    end

    def write(relative_path, content)
      @files[relative_path] = content
    end

    def remove(relative_path)
      @files.delete(relative_path)
    end

    def mkdir(relative_path)
      @files[relative_path] = nil
      reset_memoizers
    end

    def files
      @files.keys
    end

    def directories
      @directories ||= @files
        .keys
        .flat_map { |relative_path| Pathname.new(relative_path).ascend.to_a }
        .map(&:to_s)
        .uniq
    end

    def relative_path(absolute_path)
      Pathname.new(absolute_path).relative_path_from(@root).to_s
    end

    private

    def reset_memoizers
      @directories = nil
    end
  end
end
