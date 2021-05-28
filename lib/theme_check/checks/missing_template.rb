# frozen_string_literal: true
module ThemeCheck
  # Reports missing include/render/section template
  class MissingTemplate < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)
    single_file false

    def on_include(node)
      template = node.value.template_name_expr
      if template.is_a?(String)
        unless theme["snippets/#{template}"]
          add_offense("'snippets/#{template}.liquid' is not found", node: node)
        end
      end
    end
    alias_method :on_render, :on_include

    def on_section(node)
      template = node.value.section_name
      unless theme["sections/#{template}"]
        add_offense("'sections/#{template}.liquid' is not found", node: node)
      end
    end
  end
end
