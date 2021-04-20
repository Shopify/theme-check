# frozen_string_literal: true
# Note: Everything is 0-indexed here.

module ThemeCheck
  module PositionHelper
    def from_row_column_to_index(content, row, col)
      i = 0
      result = 0
      return result if content.empty?
      lines = content.lines
      while i < row
        result += lines[i].size
        i += 1
      end
      result += col
      result
    end

    def from_index_to_row_column(content, index)
      lines = content[0..index].lines
      return [0, 0] if lines.empty?
      row = lines.size - 1
      col = lines.last.size - 1
      [row, col]
    end
  end
end
