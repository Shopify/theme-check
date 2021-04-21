# frozen_string_literal: true

module ThemeCheck
  class Position
    include PositionHelper

    def initialize(needle, contents, line_number_1_indexed)
      @needle = needle
      @contents = contents
      @line_number_1_indexed = line_number_1_indexed
      @start_row_column = nil
      @end_row_column = nil
    end

    def start_line_index
      from_row_column_to_index(contents, line_number, 0)
    end

    # 0-indexed, inclusive
    def start_index
      contents.index(needle, start_line_index) || start_line_index
    end

    # 0-indexed, exclusive
    def end_index
      start_index + needle.size
    end

    def start_row
      start_row_column[0]
    end

    def start_column
      start_row_column[1]
    end

    def end_row
      end_row_column[0]
    end

    def end_column
      end_row_column[1]
    end

    private

    def contents
      return '' unless @contents.is_a?(String) && !@contents.empty?
      @contents
    end

    def line_number
      return 0 if @line_number_1_indexed.nil?
      bounded(0, @line_number_1_indexed - 1, contents.lines.size - 1)
    end

    def needle
      if @needle.nil? && !contents.empty? && !@line_number_1_indexed.nil?
        contents.lines(chomp: true)[line_number] || ''
      elsif contents.empty? || @needle.nil?
        ''
      else
        @needle
      end
    end

    def start_row_column
      return @start_row_column unless @start_row_column.nil?
      @start_row_column = from_index_to_row_column(contents, start_index)
    end

    def end_row_column
      return @end_row_column unless @end_row_column.nil?
      @end_row_column = from_index_to_row_column(contents, end_index)
    end
  end
end
