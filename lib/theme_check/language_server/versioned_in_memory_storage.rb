# frozen_string_literal: true

module ThemeCheck
  class VersionedInMemoryStorage < InMemoryStorage
    Version = Struct.new(:id, :version)

    attr_reader :versions

    def initialize(files, root = "/dev/null")
      super(files, root)
      @versions = {} # Hash<relative_path, number>
      @mutex = Mutex.new
    end

    # Motivations:
    #   - Need way for LanguageServer to know on which version of a file
    #     the check was run on, because we need to know where the
    #     TextEdit goes. If the text changed, our TextEdit might not be
    #     in the right spot. e.g.
    #
    #     Example:
    #
    #     ```
    #     Hi
    #     {{world}}
    #     ```
    #
    #     Would produce two "SpaceInsideBrace" errors:
    #
    #     - One after {{ at index 5 to 6
    #     - One before }} at index 10 to 11
    #
    #     If the user goes in and changes Hi to Sup, and _then_
    #     right clicks to apply the code edit at index 5 to 6, he'd
    #     get the following:
    #
    #     ```
    #     Sup
    #     { {world}}
    #     ```
    #
    #     Which is not a fix at all.
    #
    # Solution:
    #   - Have the LanguageServer store the version on textDocument/did{Open,Change,Close}
    #   - Have ThemeFile store the version right after @storage.read.
    #   - Add version to the diagnostic meta data
    #   - Use diagnostic meta data to determine if we can make a code edit or not
    #   - Only offer fixes on "clean" files (or offer the change but specify the version so the editor knows what to do with it)
    def write(relative_path, content, version)
      @mutex.synchronize do
        if version.nil?
          @versions.delete(relative_path)
        else
          @versions[relative_path] = version
        end
        super(relative_path, content)
      end
    end

    def read_version(relative_path)
      @mutex.synchronize { [read(relative_path), version(relative_path)] }
    end

    def remove(relative_path)
      @mutex.synchronize do
        @versions.delete(relative_path)
        super(relative_path)
      end
    end

    def versioned?
      true
    end

    def version(relative_path)
      @versions[relative_path.to_s]
    end

    def opened_files
      @versions.keys
    end
  end
end
