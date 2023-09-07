# frozen_string_literal: true
module ThemeCheck
  # Reports deeply nested {% include ... %} or {% render ... %}
  class NestedSnippet < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    class TemplateInfo < Struct.new(:includes)
      def with_deep_nested(path, templates, max, current_level = 0)
        includes.each do |node|
          template_name = filename_for(node.value.template_name_expr)
          next if path.include?(template_name)
          if current_level >= max
            yield node
          else
            new_path = path + [template_name]
            templates[template_name]
              &.with_deep_nested(new_path, templates, max, current_level + 1) { yield node }
          end
        end
      end

      def filename_for(name)
        name.include?("/") ? name : "partials/#{name}"
      end
    end

    def initialize(max_nesting_level: 3)
      @max_nesting_level = max_nesting_level
      @templates = {}
    end

    def on_document(node)
      @templates[node.theme_file.name] = TemplateInfo.new(Set.new)
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @templates[node.theme_file.name].includes << node
      end
    end
    alias_method :on_render, :on_include

    def on_end
      @templates.each_pair do |root, info|
        info.with_deep_nested([root], @templates, @max_nesting_level) do |node|
          add_offense("Too many nested snippets", node: node)
        end
      end
    end
  end
end
