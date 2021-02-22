# frozen_string_literal: true
# Note: Everything is 0-indexed here.

module ThemeCheck
  module LanguageServer
    module PositionHelper
      def from_line_column_to_index(row, col, content)
        i = 0
        result = 0
        lines = content.lines
        while i < row
          result += lines[i].size
          i += 1
        end
        result += col
        result
      end

      def from_index_to_line_column(index, content)
        lines = content[0..index].lines
        row = lines.size - 1
        col = lines.last.size - 1
        [row, col]
      end
    end
  end
end
