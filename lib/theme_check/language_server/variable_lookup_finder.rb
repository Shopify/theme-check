# frozen_string_literal: true

require 'ostruct'

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      include Constants
      extend self

      def lookup(context)
        content = context.content
        cursor = context.cursor

        return if cursor_is_on_bracket_position_that_cant_be_completed(content, cursor)
        variable_lookup = lookup_liquid_variable(content, cursor) || lookup_liquid_tag(content, cursor)

        # And we only return it if it's parsed by Liquid as VariableLookup
        return unless variable_lookup.is_a?(Liquid::VariableLookup)

        potential_lookup(variable_lookup, context)
      end

      private

      def potential_lookup(variable, context)
        return variable if context.buffer.nil? || context.buffer.empty?

        buffer = context.buffer[0...context.absolute_cursor]
        lookups = variable.lookups
        assignments = find_assignments(buffer)

        variable = assignments[variable.name] while assignments[variable.name]
        lookups = variable.lookups unless variable.lookups.empty?

        PotentialLookup.new(variable.name, lookups)
      end

      def find_assignments(buffer)
        finder = AssignmentsFinder.new(buffer)
        finder.find!
        finder.assignments
      end

      def cursor_is_on_bracket_position_that_cant_be_completed(content, cursor)
        content[0..cursor - 1] =~ ENDS_IN_BRACKET_POSITION_THAT_CANT_BE_COMPLETED
      end

      def cursor_is_on_liquid_variable_lookup_position(content, cursor)
        previous_char = content[cursor - 1]
        is_liquid_variable = content =~ Liquid::VariableStart
        is_in_variable_segment = previous_char =~ VARIABLE_LOOKUP_CHARACTERS
        is_on_blank_variable_lookup_position = content[0..cursor - 1] =~ /[{:,-]\s+$/
        (
          is_liquid_variable && (
            is_in_variable_segment ||
            is_on_blank_variable_lookup_position
          )
        )
      end

      def lookup_liquid_variable(content, cursor)
        return unless cursor_is_on_liquid_variable_lookup_position(content, cursor)
        start_index = content.match(/#{Liquid::VariableStart}-?/o).end(0) + 1
        end_index = cursor - 1

        # We take the following content
        # - start after the first two {{
        # - end at cursor position
        #
        # That way, we'll have a partial liquid variable that
        # can be parsed such that the "last" variable_lookup
        # will be the one we're trying to complete.
        markup = content[start_index..end_index]

        # Early return for incomplete variables
        return empty_lookup if markup =~ /\s+$/

        # Now we go to hack city... The cursor might be in the middle
        # of a string/square bracket lookup. We need to close those
        # otherwise the variable parse won't work.
        markup += "'" if markup.count("'").odd?
        markup += '"' if markup.count('"').odd?
        markup += "]" if markup =~ UNCLOSED_SQUARE_BRACKET

        variable = variable_from_markup(markup)

        variable_lookup_for_liquid_variable(variable)
      end

      def cursor_is_on_liquid_tag_lookup_position(content, cursor)
        markup = content[0..cursor - 1]
        is_liquid_tag = content.match?(Liquid::TagStart)
        is_in_variable_segment = markup =~ ENDS_WITH_POTENTIAL_LOOKUP
        is_on_blank_variable_lookup_position = markup =~ ENDS_WITH_BLANK_POTENTIAL_LOOKUP
        (
          is_liquid_tag && (
            is_in_variable_segment ||
            is_on_blank_variable_lookup_position
          )
        )
      end

      # Context:
      #
      # We know full well that the code as it is being typed is probably not
      # something that can be parsed by liquid.
      #
      # How this works:
      #
      # 1. Attempt to turn the code of the token until the cursor position into
      #    valid liquid code with some hacks.
      # 2. If the code ends in space at a "potential lookup" spot
      #   a. Then return an empty variable lookup
      # 3. Parse the valid liquid code
      # 4. Attempt to extract a VariableLookup from Liquid::Template
      def lookup_liquid_tag(content, cursor)
        return unless cursor_is_on_liquid_tag_lookup_position(content, cursor)

        markup = parseable_markup(content, cursor)
        return empty_lookup if markup.empty?

        template = Liquid::Template.parse(markup)
        current_tag = template.root.nodelist[0]

        case current_tag&.tag_name
        when "if", "unless"
          variable_lookup_for_if_tag(current_tag)
        when "case"
          variable_lookup_for_case_tag(current_tag)
        when "cycle"
          variable_lookup_for_cycle_tag(current_tag)
        when "for"
          variable_lookup_for_for_tag(current_tag)
        when "tablerow"
          variable_lookup_for_tablerow_tag(current_tag)
        when "render"
          variable_lookup_for_render_tag(current_tag)
        when "assign"
          variable_lookup_for_assign_tag(current_tag)
        when "echo"
          variable_lookup_for_echo_tag(current_tag)
        else
          empty_lookup
        end
      rescue Liquid::SyntaxError
        # We don't complete variable for liquid syntax errors
        empty_lookup
      end

      def parseable_markup(content, cursor = nil)
        LiquidFixer.new(content, cursor).parsable
      end

      def variable_lookup_for_if_tag(if_tag)
        condition = if_tag.blocks.last
        variable_lookup_for_condition(condition)
      end

      def variable_lookup_for_condition(condition)
        return variable_lookup_for_condition(condition.child_condition) if condition.child_condition
        return condition.right if condition.right
        condition.left
      end

      def variable_lookup_for_case_tag(case_tag)
        return variable_lookup_for_case_block(case_tag.blocks.last) unless case_tag.blocks.empty?
        case_tag.left
      end

      def variable_lookup_for_case_block(condition)
        condition.right
      end

      def variable_lookup_for_cycle_tag(cycle_tag)
        cycle_tag.variables.last
      end

      def variable_lookup_for_for_tag(for_tag)
        for_tag.collection_name
      end

      def variable_lookup_for_tablerow_tag(tablerow_tag)
        tablerow_tag.collection_name
      end

      def variable_lookup_for_render_tag(render_tag)
        return empty_lookup if render_tag.raw =~ /:\s*$/
        render_tag.attributes.values.last
      end

      def variable_lookup_for_assign_tag(assign_tag)
        variable_lookup_for_liquid_variable(assign_tag.from)
      end

      def variable_lookup_for_echo_tag(echo_tag)
        variable_lookup_for_liquid_variable(echo_tag.variable)
      end

      def variable_lookup_for_liquid_variable(variable)
        has_filters = !variable.filters.empty?

        # Can complete after trailing comma or :
        if has_filters && variable.raw =~ /[:,]\s*$/
          empty_lookup
        elsif has_filters
          last_filter_argument(variable.filters)
        elsif variable.name.nil?
          empty_lookup
        else
          variable.name
        end
      end

      def empty_lookup
        Liquid::VariableLookup.parse('')
      end

      # We want the last thing in variable.filters which is at most
      # an array that looks like [name, positional_args, hash_arg]
      def last_filter_argument(filters)
        filter = filters.last
        return filter[2].values.last if filter.size == 3
        return filter[1].last if filter.size == 2
        nil
      end

      def variable_from_markup(markup, parse_context = Liquid::ParseContext.new)
        Liquid::Variable.new(markup, parse_context)
      end

      def tag_regex(tag)
        ShopifyLiquid::Tag.tag_regex(tag)
      end
    end
  end
end
