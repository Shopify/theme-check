# frozen_string_literal: true
module PlatformosCheck
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
      @templates[node.theme_file.name] = TemplateInfo.new(Set.new, {}, Set.new)
    end

    def on_assign(node)
      @templates[node.theme_file.name].assign_nodes[node.value.to] = node
    end

    def on_include(node)
      if node.value.template_name_expr.is_a?(String)
        @templates[node.theme_file.name].includes << "snippets/#{node.value.template_name_expr}"
      end
    end

    def on_variable_lookup(node)
      @templates[node.theme_file.name].used_assigns << case node.value.name
      when Liquid::VariableLookup
        node.value.name.name
      else
        node.value.name
      end
    end

    def on_end
      @templates.each_pair do |_, info|
        used = info.collect_used_assigns(@templates)
        info.assign_nodes.each_pair do |name, node|
          next if used.include?(name)
          add_offense("`#{name}` is never used", node: node) do |corrector|
            corrector.remove(node)
          end
        end
      end
    end
  end
end
