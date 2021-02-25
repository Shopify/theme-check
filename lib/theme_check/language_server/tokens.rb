# frozen_string_literal: true

module ThemeCheck
  Token = Struct.new(
    :content,
    :start, # inclusive
    :end, # exclusive
  )

  TAG_START = Liquid::TagStart
  TAG_END = Liquid::TagEnd
  VARIABLE_START = Liquid::VariableStart
  VARIABLE_END = Liquid::VariableEnd
  SPLITTER = %r{
    (?=(?:#{TAG_START}|#{VARIABLE_START}))| # positive lookahead on tag/variable start
    (?<=(?:#{TAG_END}|#{VARIABLE_END}))     # positive lookbehind on tag/variable end
  }xom

  # Implemented as an Enumerable so we stop iterating on the find once
  # we have what we want. Kind of a perf thing.
  class Tokens
    include Enumerable

    def initialize(buffer)
      @buffer = buffer
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      chunks = @buffer.split(SPLITTER)
      chunks.shift if chunks[0]&.empty?

      prev = Token.new('', 0, 0)
      curr = Token.new('', 0, 0)

      while (content = chunks.shift)

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
