# frozen_string_literal: true
module ThemeCheck
  # Checks unused {% assign x = ... %}
  class UnusedAssign < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    class TemplateInfo < Struct.new(:used_assigns, :assign_nodes, :includes)
      def collect_used_assigns(templates, visited = Set.new)
        collected = used_assigns
        # Check recursively inside included snippets for use
        includes.each do |name|
          if templates[name] && !visited.include?(name)
            visited << name
            collected += templates[name].collect_used_assigns(templates, visited)
          end
        end
        collected
      end
    end

    def initialize
      @templates = {}
    end

    def on_document(node)
      @templates[node.template.name] = TemplateInfo.new(Set.new, {}, Set.new)
    end

    def on_assign(node)
      @templates[node.template.name].assign_nodes[node.value.to] = node
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @templates[node.template.name].includes << "snippets/#{node.value.template_name_expr}"
      end
    end

    def on_variable_lookup(node)
      @templates[node.template.name].used_assigns << node.value.name
    end

    def on_end
      @templates.each_pair do |_, info|
        used = info.collect_used_assigns(@templates)
        info.assign_nodes.each_pair do |name, node|
          unless used.include?(name)
            add_offense("`#{name}` is never used", node: node)
          end
        end
      end
    end
  end
end
