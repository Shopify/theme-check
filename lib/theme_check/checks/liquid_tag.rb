# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(min_consecutive_statements: 5)
      # @first_statement = nil
      @first_nodes = []
      @first_statement = nil
      @consecutive_statements = 0
      @min_consecutive_statements = min_consecutive_statements
      @consecutive_nodes = {}
    end

    def on_node(node)
      if node.type_name == :if
        puts node.outer_markup
      end
    end

    def on_tag(node)
      if node.inside_liquid_tag?
        reset_values
      # Ignore comments
      elsif !node.comment?
        increment_consecutive_statements(node)
      end
      #if 
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
          lines = node.source.split("\n").collect(&:rstrip)
          end_line = @consecutive_nodes[node.line_number][-1].line_number
          # TODO: test cases, other nodes with {% end__ %}
          end_line += 1 if lines[end_line] == "#{node.start_token} endif #{node.end_token}"
          consecutive = " #{lines[node.line_number - 1, end_line].join("\n ")}\n".gsub(/{%-| -%}|{%| %}/, "")
          # binding.pry
          
          if @consecutive_nodes[node.line_number][0].type_name == :if
            corrector.insert_before_node(node, "#{node.start_token} liquid\n#{consecutive}#{node.end_token}")
            @consecutive_nodes[node.line_number].each { |n| 
              corrector.remove_node(n)
            }
          else
            corrector.replace(node, "liquid\n#{consecutive}")
            @consecutive_nodes[node.line_number][1..-1].each { |n| 
              corrector.remove_node(n)
            }
          end 
        end
      end
      @first_nodes = []
    end

    def increment_consecutive_statements(node)
      @first_statement ||= node
      @consecutive_statements += 1
      @consecutive_nodes[@first_statement.line_number] = [] if !@consecutive_nodes[@first_statement.line_number]
      @consecutive_nodes[@first_statement.line_number] << node
    end

    def reset_values
      if (@consecutive_statements >= @min_consecutive_statements)
        @first_nodes << @first_statement
      end
      @first_statement = nil
      @consecutive_statements = 0
    end
  end
end
