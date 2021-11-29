# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
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
          consecutive = node.source[@consecutive_nodes[node.line_number][0].outer_markup_start_index, @consecutive_nodes[node.line_number][-1].outer_markup_end_index]
          next_tag = /(?<tag_open>({%-|{%))(?<contents>(.|\n)*?)(?<tag_close>(%}|-%}))/m.match(node.source, @consecutive_nodes[node.line_number][-1].outer_markup_end_index)
          unless next_tag.nil?
            consecutive += "\n  #{next_tag[:contents].strip}" if next_tag[:contents].strip.start_with?("end")
          end

          consecutive.gsub!(/\n/, "")
          consecutive.gsub!(/(\s?|\n)+(?=(-%}|%}))(-%}|%})/, "\n")
          consecutive.gsub!(/({%-|{%)(\s?|\n)+(?=\w)/, "  ")

          consecutive << "\n" if consecutive[-1] != "\n"
          if @consecutive_nodes[node.line_number][0].block? && node.inner_markup.lines.map(&:strip)[1..-1].all? { |l| l.start_with?("{%") && l.end_with?("%}") }
            corrector.insert_before(node, "#{node.start_token} liquid\n#{consecutive}#{node.end_token}", (node.outer_markup_start_index)...(node.outer_markup_end_index))
            @consecutive_nodes[node.line_number].each { |n| corrector.remove(n, n.outer_markup_range) }
          elsif !@consecutive_nodes[node.line_number][0].block?
            corrector.replace(node, "liquid\n#{consecutive}")
            @consecutive_nodes[node.line_number][1..-1].each { |n| corrector.remove(n, n.outer_markup_range) }
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
  end
end
