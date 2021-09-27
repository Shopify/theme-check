# frozen_string_literal: true

module ThemeCheck
  class Node
    def parent
      raise NotImplementedError
    end

    def theme_file
      raise NotImplementedError
    end

    def value
      raise NotImplementedError
    end

    def children
      raise NotImplementedError
    end

    def markup
      raise NotImplementedError
    end

    def line_number
      raise NotImplementedError
    end

    def start_index
      raise NotImplementedError
    end

    def start_row
      raise NotImplementedError
    end

    def start_column
      raise NotImplementedError
    end

    def end_index
      raise NotImplementedError
    end

    def end_row
      raise NotImplementedError
    end

    def end_column
      raise NotImplementedError
    end
  end
end
