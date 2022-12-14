# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        class ScopeVisitor
          SCOPE_UNAWARE_NODES = %i(range range_lookup variable variable_lookup)

          attr_reader :global_scope, :current_scope

          def initialize
            @node_handler = NodeHandler.new
            @global_scope = Scope.new({})
            @current_scope = Scope.new({})
          end

          def visit_template(template)
            return unless template

            visit(liquid_node(template), global_scope)
          end

          private

          def visit(node, scope)
            return if SCOPE_UNAWARE_NODES.include?(node.type_name)

            method = :"on_#{node.type_name}"
            scope = @node_handler.send(method, node, scope) if @node_handler.respond_to?(method)

            @current_scope = scope

            node.children.each { |child| visit(child, scope) }
          end

          def liquid_node(template)
            LiquidNode.new(template.root, nil, template)
          end
        end
      end
    end
  end
end
