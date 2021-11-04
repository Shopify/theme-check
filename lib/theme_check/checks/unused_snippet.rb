# frozen_string_literal: true
require "set"

module ThemeCheck
  class UnusedSnippet < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize
      @used_snippets = Set.new
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @used_snippets << "snippets/#{node.value.template_name_expr}"
      else
        # Can't reliably track unused snippets if an expression is used, ignore this check
        @used_snippets.clear
        ignore!
      end
    end
    alias_method :on_render, :on_include

    def on_end
      missing_snippets.each do |theme_file|
        add_offense("This snippet is not used", theme_file: theme_file) do |corrector|
          corrector.remove_file(@theme.storage, theme_file.relative_path.to_s)
        end
      end
    end

    def missing_snippets
      theme.snippets.reject { |t| @used_snippets.include?(t.name) }
    end
  end
end
