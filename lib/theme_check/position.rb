# frozen_string_literal: true

module ThemeCheck
  class Position
    include PositionHelper

    attr_reader :contents

    def initialize(
      needle_arg,
      contents_arg,
      line_number_1_indexed: nil,
      node_markup: nil,
      node_markup_offset: 0 # the index of markup inside the node_markup
    )
      @needle = needle_arg

      @contents = if contents_arg&.is_a?(String) && !contents_arg.empty?
        contents_arg
      else
        ''
      end

      @line_number_1_indexed = line_number_1_indexed
      @node_markup_offset = node_markup_offset
      @node_markup = node_markup
    end

    def start_line_offset
      @start_line_offset ||= from_row_column_to_index(contents, line_number, 0)
    end

    def start_offset
      @start_offset ||= compute_start_offset
    end

    def strict_position
      @strict_position ||= StrictPosition.new(
        needle,
        contents,
        start_index,
      )
    end

    # 0-indexed, inclusive
    def start_index
      contents.index(needle, start_offset)
    end

    # 0-indexed, exclusive
    def end_index
      strict_position.end_index
    end

    # 0-indexed, inclusive
    def start_row
      strict_position.start_row
    end

    # 0-indexed, inclusive
    def start_column
      strict_position.start_column
    end

    # 0-indexed, exclusive (both taken together are) therefore you
    # might end up on a newline character or the next line
    def end_row
      strict_position.end_row
    end

    def end_column
      strict_position.end_column
    end

    def content_line_count
      @content_line_count ||= contents.count("\n")
    end

    private

    def compute_start_offset
      return start_line_offset if @node_markup.nil?
      node_markup_start = contents.index(@node_markup, start_line_offset)
      return start_line_offset if node_markup_start.nil?
      node_markup_start + @node_markup_offset
    end

    def line_number
      return 0 if @line_number_1_indexed.nil?
      bounded(0, @line_number_1_indexed - 1, content_line_count)
    end

    def needle
      @cached_needle ||= if has_content_and_line_number_but_no_needle?
        entire_line_needle
      elsif contents.empty? || @needle.nil?
        ''
      elsif !can_find_needle?
        entire_line_needle
      else
        @needle
      end
    end

    def has_content_and_line_number_but_no_needle?
      @needle.nil? && !contents.empty? && @line_number_1_indexed.is_a?(Integer)
    end

    def can_find_needle?
      !!contents.index(@needle, start_offset)
    end

    def entire_line_needle
      contents.lines(chomp: true)[line_number] || ''
    end
  end

  # This method is stricter than Position in the sense that it doesn't
  # accept invalid inputs. Makes for code that is easier to understand.
  class StrictPosition
    include PositionHelper

    attr_reader :needle, :contents

    def initialize(needle, contents, start_index)
      raise ArgumentError, 'Bad start_index' unless start_index.is_a?(Integer)
      raise ArgumentError, 'Bad contents' unless contents.is_a?(String)
      raise ArgumentError, 'Bad needle' unless needle.is_a?(String) || !contents.index(needle, start_index)

      @needle = needle
      @contents = contents
      @start_index = start_index
      @start_row_column = nil
      @end_row_column = nil
    end

    # 0-indexed, inclusive
    def start_index
      @contents.index(needle, @start_index)
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
