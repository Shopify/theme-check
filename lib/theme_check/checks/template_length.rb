# frozen_string_literal: true
module ThemeCheck
  class TemplateLength < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(max_length: 500, exclude_schema: true, exclude_stylesheet: true, exclude_javascript: true)
      @max_length = max_length
      @exclude_schema = exclude_schema
      @exclude_stylesheet = exclude_stylesheet
      @exclude_javascript = exclude_javascript
    end

    def on_document(_node)
      @excluded_lines = 0
    end

    def on_schema(node)
      exclude_node_lines(node) if @exclude_schema
    end

    def on_stylesheet(node)
      exclude_node_lines(node) if @exclude_stylesheet
    end

    def on_javascript(node)
      exclude_node_lines(node) if @exclude_javascript
    end

    def after_document(node)
      lines = node.template.source.count("\n") - @excluded_lines
      if lines > @max_length
        add_offense("Template has too many lines [#{lines}/#{@max_length}]", template: node.template)
      end
    end

    private

    def exclude_node_lines(node)
      @excluded_lines += node.value.nodelist.join.count("\n")
    end
  end
end
