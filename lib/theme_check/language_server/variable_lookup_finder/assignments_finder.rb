# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        include RegexHelpers

        attr_reader :assignments, :content

        def initialize(content)
          @content = content
          @assignments = {}
        end

        def find!
          liquid_lines.each { |line| visit_line(line) }
        end

        private

        def liquid_lines
          matches(content + '%}', LIQUID_TAG_OR_VARIABLE)
            .flat_map { |match| match[0].lines }
        end

        def visit_line(line)
          template = parse(line)

          visitor(template).visit if template
        end

        def parse(content)
          parsable = LiquidFixer.new(content).parsable

          unless parsable.empty?
            Liquid::Template.parse(parsable)
          end
        rescue Liquid::SyntaxError
          # Ignore parse errors.
        end

        def visitor(template)
          Liquid::ParseTreeVisitor
            .for(template.root)
            .add_callback_for(Liquid::Assign) { |node| on_assign_node(node) }
        end

        def on_assign_node(node)
          assignments[node.to] = node.from.name
        end
      end
    end
  end
end
