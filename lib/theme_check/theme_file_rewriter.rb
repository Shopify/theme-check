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

    def insert_before(node, content, character_range = nil)
      @rewriter.insert_before(
        range(
          character_range&.begin || node.start_index,
          character_range&.end || node.end_index,
        ),
        content
      )
    end

    def insert_after(node, content, character_range = nil)
      @rewriter.insert_after(
        range(
          character_range&.begin || node.start_index,
          character_range&.end || node.end_index,
        ),
        content
      )
    end

    def remove(node)
      @rewriter.remove(
        range(node.outer_markup_start_index, node.outer_markup_end_index)
      )
    end

    def replace(node, content, character_range = nil)
      @rewriter.replace(
        range(
          character_range&.begin || node.start_index,
          character_range&.end || node.end_index,
        ),
        content
      )
    end

    def replace_inner_markup(node, content)
      @rewriter.replace(
        range(node.inner_markup_start_index, node.inner_markup_end_index),
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
