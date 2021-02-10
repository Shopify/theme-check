# frozen_string_literal: true

module ThemeCheck
  class Corrector
    def initialize(template:)
      @template = template
    end

    def insert_after(node, content)
      line = @template.full_line(node.line_number)
      line.insert(node.range[1] + 1, content)
    end

    def insert_before(node, content)
      line = @template.full_line(node.line_number)
      line.insert(node.range[0], content)
    end

    def replace(node, content)
      line = @template.full_line(node.line_number)
      line[node.range[0]..node.range[1]] = content
      node.markup = content
    end

    def wrap(node, insert_before, insert_after)
      line = @template.full_line(node.line_number)
      line.insert(node.range[0], insert_before)
      line.insert(node.range[1] + 1 + insert_before.length, insert_after)
    end
  end
end
