# frozen_string_literal: true

module ThemeCheck
  Token = Struct.new(
    :content,
    :start_line,
    :start_col,
    :end_line,
    :end_col,
  )

  # Implemented as an Enumerable so we stop iterating on the find once
  # we have what we want. Kind of a perf thing.
  class Tokens
    include Enumerable

    def initialize(buffer)
      @buffer = buffer
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      tokenizer = Liquid::Tokenizer.new(@buffer, true)

      prev = Token.new('', 0, 0, 0, 0)
      curr = Token.new('', 0, 0, 0, 0)

      while (curr.start_line = tokenizer.line_number) && (content = tokenizer.shift)
        curr.start_col = if prev.end_line == curr.start_line
          prev.end_col + 1
        else
          1
        end

        curr.end_line = tokenizer.line_number
        curr.end_col = if curr.start_line == curr.end_line
          curr.start_col + content.size - 1
        else
          content.lines.last.size
        end

        block.call(Token.new(
          content,
          curr.start_line,
          curr.start_col,
          curr.end_line,
          curr.end_col,
        ))

        # recycling structs
        tmp = prev
        prev = curr
        curr = tmp
      end
    end
  end
end
