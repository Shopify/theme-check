# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(min_consecutive_statements: 5)
      @consecutive_statements = []
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
      @consecutive_statements << node.markup
    end

    def reset_consecutive_statements
      if @consecutive_statements.length >= @min_consecutive_statements
        result = "liquid\n"

        @consecutive_statements.each do |statement|
          result += "#{statement} \n"
        end

        add_offense("Use {% liquid ... %} to write multiple tags", node: @consecutive_statements[0]) do |corrector|
          corrector.replace(@consecutive_statements[0], result)
        end
      end
      @first_statement = nil
      @consecutive_statements = []
    end
  end
end
