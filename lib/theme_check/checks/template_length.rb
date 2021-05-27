# frozen_string_literal: true
module ThemeCheck
  class TemplateLength < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(max_length: 200, exclude_schema: true)
      @max_length = max_length
      @exclude_schema = exclude_schema
    end

    def on_document(_node)
      @excluded_lines = 0
    end

    def on_schema(node)
      if @exclude_schema
        @excluded_lines += node.value.nodelist.join.count("\n")
      end
    end

    def after_document(node)
      lines = node.template.source.count("\n") - @excluded_lines
      if lines > @max_length
        add_offense("Template has too many lines [#{lines}/#{@max_length}]", template: node.template)
      end
    end
  end
end
