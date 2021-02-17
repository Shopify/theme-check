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

      # This code is 1-indexed because Liquid::Tokenizer is 1-indexed.
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
          # We convert it back to 0-index to fit with our own world.
          curr.start_line - 1,
          curr.start_col - 1,
          curr.end_line - 1,
          curr.end_col - 1,
        ))

        # recycling structs
        tmp = prev
        prev = curr
        curr = tmp
      end
    end
  end
end
