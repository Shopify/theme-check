# frozen_string_literal: true

module ThemeCheck
  class Storage
    def path(relative_path)
      raise NotImplementedError
    end

    def read(relative_path)
      raise NotImplementedError
    end

    def write(relative_path, content)
      raise NotImplementedError
    end

    def files
      raise NotImplementedError
    end

    def directories
      raise NotImplementedError
    end
  end
end
