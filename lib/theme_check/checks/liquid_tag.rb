# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
    include RegexHelpers
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(min_consecutive_statements: 5)
      @min_consecutive_statements = min_consecutive_statements
    end

    def on_document(_node)
      @first_nodes = []
      @consecutive_nodes = {}
      @first_statement = nil
      @consecutive_statements = 0
    end

    def on_tag(node)
      if node.inside_liquid_tag?
        reset_values
      # Ignore comments
      elsif !node.comment?
        increment_consecutive_statements(node)
      end
    end

    def on_string(node)
      # Only reset the counter on outputted strings, and ignore empty line-breaks
      if node.parent.block? && !node.value.strip.empty?
        reset_values
      end
    end

    def after_document(_node)
      reset_values
      @first_nodes.each do |node|
        add_offense("Use {% liquid ... %} to write multiple tags", node: node) do |corrector|
          nodes = @consecutive_nodes[node.line_number]
          first_node = @consecutive_nodes[node.line_number][0]
          last_node = @consecutive_nodes[node.line_number][-1]

          if first_node.block? && all_branches_liquid_tags?(first_node)
            corrector.insert_before(node, render_liquid_tag(first_node, last_node), node.outer_markup_range)
            nodes.each { |n| corrector.remove(n, n.outer_markup_range) }
          elsif !first_node.block?
            corrector.replace(node, render_liquid_tag(first_node, last_node))
            nodes[1..-1].each { |n| corrector.remove(n, n.outer_markup_range) }
          end
        end
      end
    end

    def increment_consecutive_statements(node)
      @first_statement ||= node
      @consecutive_statements += 1
      @consecutive_nodes[@first_statement.line_number] = [] unless @consecutive_nodes[@first_statement.line_number]
      @consecutive_nodes[@first_statement.line_number] << node
    end

    def reset_values
      if @consecutive_statements >= @min_consecutive_statements
        @first_nodes << @first_statement
      end
      @first_statement = nil
      @consecutive_statements = 0
    end

    def render_liquid_tag(first_node, last_node)
      markup = construct_liquid_tag(first_node, last_node)
      if first_node.block?
        "#{first_node.start_token} #{markup}#{first_node.end_token}"
      else
        markup
      end
    end

    def construct_liquid_tag(first_node, last_node)
      consecutive = first_node.source[first_node.outer_markup_start_index, last_node.outer_markup_end_index]
      next_tag = /(?<tag_open>({%-|{%))(?<contents>(.|\n)*?)(?<tag_close>(%}|-%}))/m.match(first_node.source, last_node.outer_markup_end_index)

      unless next_tag.nil?
        consecutive += "\n  #{next_tag[:contents].strip}\n" if next_tag[:contents].strip.start_with?("end")
      end

      remove_tags(consecutive)
      consecutive << "\n" if consecutive[-1] != "\n"
      "liquid\n#{consecutive}"
    end

    def remove_tags(consecutive)
      consecutive.gsub!(/\n/, "")
      consecutive.gsub!(TRAILING_WHITESPACE_AND_CLOSING_LIQUID_TAG, "\n")
      consecutive.gsub!(OPENING_LIQUID_TAG_AND_LEADING_WHITESPACE, "  ")
    end

    def all_branches_liquid_tags?(node)
      return false unless node.block?
      node.inner_markup.lines.map(&:strip)[1..-1].all? { |line| line.start_with?("{%") && line.end_with?("%}") }
    end
  end
end
