# frozen_string_literal: true
module ThemeCheck
  # Reports missing content_for_header and content_for_layout in theme.liquid
  class RequiredLayoutThemeObject < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    LAYOUT_FILENAME = "layout/theme"

    def initialize
      @content_for_layout_found = false
      @content_for_header_found = false
    end

    def on_document(node)
      @layout_theme_node = node if node.theme_file.name == LAYOUT_FILENAME
    end

    def on_variable(node)
      return unless node.value.name.is_a?(Liquid::VariableLookup)

      @content_for_header_found ||= node.value.name.name == "content_for_header"
      @content_for_layout_found ||= node.value.name.name == "content_for_layout"
    end

    def after_document(node)
      return unless node.theme_file.name == LAYOUT_FILENAME

      add_missing_object_offense("content_for_layout", "</body>") unless @content_for_layout_found
      add_missing_object_offense("content_for_header", "</head>") unless @content_for_header_found
    end

    private

    def add_missing_object_offense(name, tag)
      add_offense("#{LAYOUT_FILENAME} must include {{#{name}}}", node: @layout_theme_node) do
        if @layout_theme_node.source.index(tag)
          @layout_theme_node.source.insert(@layout_theme_node.source.index(tag), "  {{ #{name} }}\n  ")
          @layout_theme_node.markup = @layout_theme_node.source
        end
      end
    end
  end
end
