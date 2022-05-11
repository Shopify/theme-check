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
  HTML_TAG_START = %r{<(?=[/a-z])}i
  HTML_TAG_END = />/

  # Implemented as an Enumerable so we stop iterating on the find once
  # we have what we want. Kind of a perf thing.
  class Tokens
    include Enumerable

    def initialize(buffer)
      @buffer = buffer
    end

    # Boi I'm so sorry. So this thing here sucks balls and is ugly af
    # because we want to _pseudo_ tokenize the file as it is being
    # written even though it might not parse properly. So "invalid"
    # tokens or unclosed tokens are OK and we should somehow split
    # that in a manner that the CompletionProvider or HoverProviders
    # can understand.
    #
    # There's a catch:
    # - {% if token > hello %} should come in as one token
    # - {% if token < hello %} should come in as one token
    # - {% if token <div should come in as 2 and split on <
    #
    # We do this by branching our regexes.
    # - If we open a html tag, look for a close html tag or any open tag.
    # - If we open a liquid tag, look for a close liquid tag or any open tag.
    # - If we open a liquid drop, look for a close liquid drop or any open tag.
    #
    # And some more...
    def each(&block)
      return to_enum(:each) unless block_given?

      cursor = 0

      while cursor <= @buffer.size
        closest_open_match = /#{HTML_TAG_START}|#{VARIABLE_START}|#{TAG_START}|#{HTML_TAG_END}/oi.match(@buffer, cursor)
        return block.call(token(cursor, -1)) unless closest_open_match

        head = closest_open_match.begin(0)
        tail = -1

        head += 1 if closest_open_match[0] == '>'
        block.call(token(cursor, head)) if head > cursor
        if closest_open_match[0] == '>'
          cursor = head
          next
        end

        case closest_open_match[0]
        when '<'
          closest_close_match = /#{HTML_TAG_END}|#{TAG_START}|#{VARIABLE_START}|\Z/oi.match(@buffer, closest_open_match.end(0))
          return block.call(token(head, -1)) unless closest_close_match
          tail = closest_close_match.begin(0)
          tail += 1 if closest_close_match[0] == '>'
        when '{{'
          closest_close_match = /#{VARIABLE_END}|#{TAG_START}|#{VARIABLE_START}|#{HTML_TAG_START}|\Z/oi.match(@buffer, closest_open_match.end(0))
          return block.call(token(head, -1)) unless closest_close_match
          tail = closest_close_match.begin(0)
          tail += 2 if closest_close_match[0] == '}}'
        when '{%'
          closest_close_match = /#{TAG_END}|#{TAG_START}|#{VARIABLE_START}|#{HTML_TAG_START}|\Z/oi.match(@buffer, closest_open_match.end(0))
          return block.call(token(head, -1)) unless closest_close_match
          tail = closest_close_match.begin(0)
          tail += 2 if closest_close_match[0] == '%}'
        end

        block.call(token(head, tail))

        cursor = tail

        return if cursor == -1
        return if cursor == @buffer.size
      end
    end

    def token(head, tail = -1)
      Token.new(
        @buffer[head...tail],
        head,
        tail == -1 ? @buffer.size : tail,
      )
    end
  end
end
