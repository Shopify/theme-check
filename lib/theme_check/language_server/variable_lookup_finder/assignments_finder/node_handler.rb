# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        class NodeHandler
          def on_assign(node, scope)
            # When a variable is redefined in a new scope we
            # no longer can guarantee the type in the global scope
            #
            # Example:
            # ```liquid
            # {%- liquid
            #   assign var1 = some_value
            #
            #   if condition
            #     assign var1 = another_value
            #            ^^^^ from here we no longer can guarantee
            #                 the type of `var1` in the global scope
            # -%}
            # ```
            p_scope = scope
            while (p_scope = p_scope.parent)
              p_scope.variables.delete(node.value.to)
            end

            scope << node
            scope
          end

          ##
          # Table row tags do not rely on blocks to define scopes,
          # so we index their value here
          def on_table_row(node, scope)
            scope = scope.new_child

            scope << node
            scope
          end

          ##
          # Define a new scope every time a new block is created
          def on_block_body(node, scope)
            scope = scope.new_child

            ##
            # 'for' tags handle blocks flattenly and differently
            # than the other tags (if, unless, case).
            #
            # The scope of 'for' tags exists only in the first
            # block, as the following one refers to the else
            # statement of the iteration.
            parent = node.parent

            scope << parent if parent.type_name == :for && parent.children.first == node
            scope
          end
        end
      end
    end
  end
end
