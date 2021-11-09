# frozen_string_literal: true

require 'parser'

module ThemeCheck
  class ThemeFileRewriter
    def initialize(name, source)
      @buffer = Parser::Source::Buffer.new(name, source: source)
      @rewriter = Parser::Source::TreeRewriter.new(
        @buffer
      )
    end

    def insert_before(node, content)
      @rewriter.insert_before(
        range(node.start_index, node.end_index),
        content
      )
    end

    def insert_after(node, content)
      @rewriter.insert_after(
        range(node.start_index, node.end_index),
        content
      )
    end

    def remove(node)
      @rewriter.remove(
        range(node.start_token_index, node.end_token_index)
      )
    end

    def replace(node, content)
      @rewriter.replace(
        range(node.start_index, node.end_index),
        content
      )
    end

    def replace_body(node, content)
      @rewriter.replace(
        range(node.block_body_start_index, node.block_body_end_index),
        content
      )
    end

    def wrap(node, insert_before, insert_after)
      @rewriter.wrap(
        range(node.start_index, node.end_index),
        insert_before,
        insert_after,
      )
    end

    def to_s
      @rewriter.process
    end

    private

    def range(start_index, end_index)
      Parser::Source::Range.new(
        @buffer,
        start_index,
        end_index,
      )
    end
  end
end
