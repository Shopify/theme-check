require "set"

module ThemeCheck
  class UnusedSnippets < Check
    severity :suggestion

    def initialize
      @used_templates = Set.new
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @used_templates << "snippets/#{node.value.template_name_expr}.liquid"
      else
        # Can't reliably track unused snippets if an expression is used, ignore this check
        @used_templates.clear
        ignore!
      end
    end
    alias_method :on_render, :on_include

    def on_end
      (theme.snippets - @used_templates.to_a).each do |template|
        add_offense("This template is not used", template: template)
      end
    end
  end
end
