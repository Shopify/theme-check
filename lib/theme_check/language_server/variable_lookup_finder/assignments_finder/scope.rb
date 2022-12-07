# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class AssignmentsFinder
        class Scope < Struct.new(:variables, :parent)
          include TypeHelper

          def new_child
            child_scope = dup
            child_scope.variables = variables.dup
            child_scope.parent = self
            child_scope
          end

          def <<(node)
            tag = node.value

            case tag
            when Liquid::Assign
              variable_name = tag.to
              variables[variable_name] = assign_tag_as_potential_lookup(tag)
            when Liquid::For, Liquid::TableRow
              variable_name = tag.variable_name
              variables[variable_name] = iteration_tag_as_potential_lookup(tag)
            end
          end

          private

          def assign_tag_as_potential_lookup(tag)
            variable_lookup = tag.from.name

            unless variable_lookup.is_a?(Liquid::VariableLookup)
              return PotentialLookup.new(input_type_of(variable_lookup), [], variables)
            end

            name = variable_lookup.name
            lookups = variable_lookup.lookups

            PotentialLookup.new(name, lookups, variables)
          end

          def iteration_tag_as_potential_lookup(tag)
            variable_lookup = tag.collection_name

            name = variable_lookup.name
            lookups = [*variable_lookup.lookups, 'first']

            PotentialLookup.new(name, lookups, variables)
          end
        end
      end
    end
  end
end
