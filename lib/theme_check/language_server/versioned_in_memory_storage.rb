# frozen_string_literal: true

module ThemeCheck
  class VersionedInMemoryStorage < InMemoryStorage
    Version = Struct.new(:id, :version)

    attr_reader :versions

    def initialize(files, root = "/dev/null")
      super(files, root)
      @versions = {}
      @mutex = Mutex.new
    end

    # Motivations:
    #   - Don't want to change "core" code because of LanguageServer
    #   - Don't want "core" code to think about Threads
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
    #   - Don't want to add a synchronize block around the read + version check, so maintain a map of object_id -> version.
    #   - Add version to the diagnostic meta data
    #   - Use diagnostic meta data to determine if we can make a code edit or not
    #   - Only offer fixes on "clean" files (or offer the change but specify the version so the editor knows what to do with it)
    def write(relative_path, content, version)
      @mutex.synchronize do
        set_version(relative_path, content, version)
        super(relative_path, content)
      end
    end

    def version(relative_path, content)
      @versions[relative_path.to_s]
        &.find { |version| version.id == content.object_id }
        &.version
    end

    def latest_version(relative_path)
      @versions[relative_path.to_s]
        &.last
        &.version
    end

    def set_version(relative_path, content, version)
      relative_path = relative_path.to_s unless relative_path.is_a?(String)
      @versions[relative_path] ||= []
      @versions[relative_path] << Version.new(content.object_id, version)

      # only keep five versions around, otherwise this object grows unboundedly
      # as we get more changes in. And you get changes QUITE OFTEN!
      @versions[relative_path].shift while @versions[relative_path].size > 5
    end
  end
end
