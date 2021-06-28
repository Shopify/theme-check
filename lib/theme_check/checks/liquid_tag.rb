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
    end

    def on_tag(node)
      if !node.inside_liquid_tag?
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
    end

    def reset_consecutive_statements
      if @consecutive_statements >= @min_consecutive_statements
        add_offense("Use {% liquid ... %} to write multiple tags", node: @first_statement)
      end
      @first_statement = nil
      @consecutive_statements = 0
    end
  end
end
