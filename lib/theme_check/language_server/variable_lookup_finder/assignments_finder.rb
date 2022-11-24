# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        include RegexHelpers

        attr_reader :content

        def initialize(content)
          @content = close_tag(content)
          @global_scope = {}
          @current_scope = {}
        end

        def find!
          template = parse(content)

          if template
            visit_template(template)
            return
          end

          liquid_tags.each do |tag|
            visit_template(last_line_parse(tag))
          end
        end

        def assignments
          @current_scope
        end

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
          @global_scope.delete(node.value.to) unless scope.equal?(@global_scope)

          index!(scope, node)

          scope
        end

        ##
        # Table row tags do not rely on blocks to define scopes,
        # so we index their value here
        def on_table_row(node, scope)
          scope = scope.dup

          index!(scope, node)

          scope
        end

        ##
        # Define a new scope every time a new block is created
        def on_block_body(node, scope)
          scope = scope.dup

          ##
          # 'for' tags handle blocks flattenly and differently
          # than the other tags (if, unless, case).
          #
          # The scope of 'for' tags exists only in the first
          # block, as the following one refers to the else
          # statement of the iteration.
          parent = node.parent
          if parent.type_name == :for && parent.children.first == node
            index!(scope, parent)
          end

          scope
        end

        private

        def index!(scope, node)
          tag = node.value
          variable = nil
          name = nil
          lookups = []

          case tag
          when Liquid::Assign
            variable = tag.to
            variable_lookup = tag.from.name

            name = variable_lookup.name
            lookups = variable_lookup.lookups
          when Liquid::For, Liquid::TableRow
            variable = tag.variable_name
            variable_lookup = tag.collection_name

            name = variable_lookup.name
            lookups = [*variable_lookup.lookups, 'first']
          end

          scope[variable] = PotentialLookup.new(name, lookups, scope)
        end

        def liquid_tags
          matches(content, LIQUID_TAG_OR_VARIABLE)
            .flat_map { |match| match[0] }
        end

        def visit_template(template)
          return unless template

          node = LiquidNode.new(template.root, nil, template)

          visit(node, @global_scope)
        end

        def visit(node, scope, level = 0)
          return if node.type_name == :variable_lookup

          method = :"on_#{node.type_name}"
          scope = send(method, node, scope) if respond_to?(method)

          @current_scope = scope

          node.children.each { |child| visit(child, scope, level + 1) }
        end

        def parse(content)
          regular_parse(content) || tolerant_parse(content)
        end

        def regular_parse(content)
          Liquid::Template.parse(content)
        rescue Liquid::SyntaxError
          # Ignore syntax errors at the regular parse phase
        end

        def tolerant_parse(content)
          TolerantParser::Template.parse(content)
        rescue StandardError
          # Ignore any error at the tolerant parse phase
        end

        def last_line_parse(content)
          parsable_content = LiquidFixer.new(content).parsable

          regular_parse(parsable_content)
        end

        def close_tag(content)
          lines = content.lines
          end_tag = lines.last =~ VARIABLE_START ? ' }}' : ' %}'

          content + end_tag
        end
      end
    end
  end
end
