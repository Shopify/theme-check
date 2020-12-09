# frozen_string_literal: true
module ThemeCheck
  class TemplateLength < LiquidCheck
    severity :suggestion
    category :liquid

    def initialize(max_length: 200)
      @max_length = max_length
    end

    def on_document(node)
      lines = node.template.source.count("\n")
      if lines > @max_length
        add_offense("Template has too many lines [#{lines}/#{@max_length}]", template: node.template)
      end
    end
  end
end
