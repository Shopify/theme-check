# frozen_string_literal: true

module ThemeCheck
  class VersionedInMemoryStorage < InMemoryStorage
    attr_reader :versions

    def initialize(files, root)
      super(files, root)
      @versions = {}
    end

    def set_version(relative_path, version)
      versions[relative_path] = version
    end

    def version(relative_path)
      versions[relative_path]
    end
  end
end
