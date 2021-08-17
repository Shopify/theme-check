# frozen_string_literal: true
module ThemeCheck
  # Reports missing include/render/section template
  class MissingTemplate < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)
    single_file false

    def initialize(ignore_missing: [])
      @ignore_missing = ignore_missing
    end

    def on_include(node)
      template = node.value.template_name_expr
      if template.is_a?(String)
        add_missing_offense("snippets/#{template}", node: node)
      end
    end
    alias_method :on_render, :on_include

    def on_section(node)
      template = node.value.section_name
      add_missing_offense("sections/#{template}", node: node)
    end

    private

    def ignore?(path)
      @ignore_missing.any? { |pattern| File.fnmatch?(pattern, path) }
    end

    def add_missing_offense(name, node:)
      path = "#{name}.liquid"
      unless ignore?(path) || theme[name]
        add_offense("'#{path}' is not found", node: node)
      end
    end
  end
end
