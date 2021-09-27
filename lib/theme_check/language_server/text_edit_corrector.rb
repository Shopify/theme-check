# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class TextEditCorrector
      attr_reader :edits

      def initialize
        @edits = []
      end

      # @param node [Node]
      def insert_after(node, content)
        @edits << {
          range: range(node),
          newText: node.markup + content,
        }
      end

      # @param node [Node]
      def insert_before(node, content)
        @edits << {
          range: range(node),
          newText: content + node.markup,
        }
      end

      def replace(node, content)
        @edits << {
          range: range(node),
          newText: content,
        }
      end

      def wrap(node, insert_before, insert_after)
        @edits << {
          range: range(node),
          newText: insert_before + node.markup + insert_after,
        }
      end

      private

      # @param node [ThemeCheck::Node]
      def range(node)
        {
          start: {
            line: node.start_row,
            character: node.start_column,
          },
          end: {
            line: node.end_row,
            character: node.end_column,
          },
        }
      end

      def start_position(node)
        {
          line: node.start_row,
          character: node.start_column,
        }
      end

      def end_position(node)
        {
          line: node.end_row,
          character: node.end_column,
        }
      end
    end
  end
end
