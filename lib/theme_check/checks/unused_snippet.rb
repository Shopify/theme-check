# frozen_string_literal: true
require "set"

module ThemeCheck
  class UnusedSnippet < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize
      @used_templates = Set.new
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @used_templates << "snippets/#{node.value.template_name_expr}"
      else
        # Can't reliably track unused snippets if an expression is used, ignore this check
        @used_templates.clear
        ignore!
      end
    end
    alias_method :on_render, :on_include

    def on_end
      missing_snippets.each do |template|
        add_offense("This template is not used", template: template)
      end
    end

    def missing_snippets
      theme.snippets.reject { |t| @used_templates.include?(t.name) }
    end
  end
end
