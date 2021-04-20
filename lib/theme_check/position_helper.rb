# frozen_string_literal: true
# Note: Everything is 0-indexed here.

module ThemeCheck
  module PositionHelper
    def from_row_column_to_index(content, row, col)
      return 0 unless content.is_a?(String) && !content.empty?
      return 0 unless row.is_a?(Integer) && col.is_a?(Integer)
      i = 0
      result = 0
      safe_row = bounded(0, row, content.lines.size - 1)
      lines = content.lines
      line_size = lines[i].size
      while i < safe_row
        result += line_size
        i += 1
        line_size = lines[i].size
      end
      result += bounded(0, col, line_size - 1)
      result
    end

    def from_index_to_row_column(content, index)
      return [0, 0] unless content.is_a?(String) && !content.empty?
      return [0, 0] unless index.is_a?(Integer)
      safe_index = bounded(0, index, content.size - 1)
      lines = content[0..safe_index].lines
      row = lines.size - 1
      col = lines.last.size - 1
      [row, col]
    end

    def bounded(a, x, b)
      [a, [x, b].min].max
    end
  end
end
