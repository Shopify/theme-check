# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(min_consecutive_statements: 5)
      @first_statement = nil
      @consecutive_statements = 0
      @min_consecutive_statements = min_consecutive_statements
      @consecutive_nodes = []
    end

    def on_tag(node)
      if node.inside_liquid_tag?
        reset_consecutive_statements
      # Ignore comments
      elsif !node.comment?
        increment_consecutive_statements(node)
      end
    end

    def on_string(node)
      # Only reset the counter on outputted strings, and ignore empty line-breaks
      if node.parent.block? && !node.value.strip.empty?
        reset_consecutive_statements
      end
    end

    def after_document(_node)
      reset_consecutive_statements
    end

    def increment_consecutive_statements(node)
      @first_statement ||= node
      @consecutive_statements += 1
      @consecutive_nodes << node
    end

    def reset_consecutive_statements
      if (@consecutive_statements >= @min_consecutive_statements) && @first_statement
        add_offense("Use {% liquid ... %} to write multiple tags", node: @first_statement) do |corrector|
          next if @first_statement.nil?
          lines = @first_statement.source.split("\n").collect(&:rstrip)
          # remove tags to be replaced by liquid tag
          @first_statement.source.sub!("\n#{lines[@consecutive_nodes[1].line_number - 1, @consecutive_nodes[-1].line_number].join("\n")}", "")
          # construct liquid tag with consecutive nodes (remove opening/closing tags + add liquid to opening tag)
          consecutive = " #{lines[@first_statement.line_number - 1, @consecutive_nodes[-1].line_number + 1].join("\n ")}\n".gsub(/({%| %})/, "")
          corrector.replace(@first_statement, "liquid\n#{consecutive}")
          reset_values
        end
      else
        reset_values
      end
    end

    def reset_values
      @first_statement = nil
      @consecutive_statements = 0
      @consecutive_nodes = []
    end
  end
end
