# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        include RegexHelpers

        attr_reader :content, :scope_visitor

        def initialize(content)
          @content = close_tag(content)
          @scope_visitor = ScopeVisitor.new
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
          current_scope = scope_visitor.current_scope
          current_scope.variables
        end

        private

        def visit_template(template)
          scope_visitor.visit_template(template)
        end

        def liquid_tags
          matches(content, LIQUID_TAG_OR_VARIABLE)
            .flat_map { |match| match[0] }
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
