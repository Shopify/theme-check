# frozen_string_literal: true

module ThemeCheck
  Token = Struct.new(
    :content,
    :start, # inclusive
    :end, # exclusive
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

      prev = Token.new('', 0, 0)
      curr = Token.new('', 0, 0)

      while (content = tokenizer.shift)
        content += tokenizer.shift if content == "{%"

        curr.start = prev.end
        curr.end = curr.start + content.size

        block.call(Token.new(
          content,
          curr.start,
          curr.end,
        ))

        # recycling structs
        tmp = prev
        prev = curr
        curr = tmp
      end
    end
  end
end
