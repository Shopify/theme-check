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

    def on_render(node)
      if node.value.template_name_expr.is_a?(String)
        @used_snippets << "snippets/#{node.value.template_name_expr}"

      elsif might_have_a_block_as_variable_lookup?(node)
        # We ignore this case, because that's a "proper" use case for
        # the render tag with OS 2.0
        # {% render block %} shouldn't turn off the UnusedSnippet check

      else
        # Can't reliably track unused snippets if an expression is used, ignore this check
        @used_snippets.clear
        ignore!
      end
    end
    alias_method :on_include, :on_render

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

    private

    # This function returns true when the render node passed might have a
    # variable lookup that refers to a block as template_name_expr.
    #
    # e.g.
    #
    # {% for block in col %}
    #   {% render block %}
    # {% endfor %}
    #
    # In this case, the `block` variable_lookup in the render tag might be
    # a Block because col might be an array of blocks.
    #
    # @param node [Node]
    def might_have_a_block_as_variable_lookup?(node)
      return false unless node.type_name == :render

      return false unless node.value.template_name_expr.is_a?(Liquid::VariableLookup)

      name = node.value.template_name_expr.name
      return false unless name.is_a?(String)

      # We're going through all the parents of the nodes until we find
      # a For node with variable_name === to the template_name_expr's name
      find_parent(node.parent) do |parent_node|
        next false unless parent_node.type_name == :for

        parent_node.value.variable_name == name
      end
    end

    # @param node [Node]
    def find_parent(node, &pred)
      return nil unless node

      return node if yield node

      find_parent(node.parent, &pred)
    end
  end
end
